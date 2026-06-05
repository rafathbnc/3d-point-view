import ARKit
import simd

/// Converts an ARKit depth map + camera image into a packed Float32 point cloud buffer.
///
/// Wire format of the returned Data:
///   Bytes 0-3  : Int32 little-endian — point count N
///   Bytes 4-end: Float32[N × 6]   — interleaved [x, y, z, r, g, b, ...]
///                r/g/b are normalised to [0, 1]
class DepthProcessor {

    static func processToData(
        depthMap: CVPixelBuffer,
        confidenceMap: CVPixelBuffer?,
        cameraImage: CVPixelBuffer,
        cameraIntrinsics: simd_float3x3,
        imageResolution: CGSize,
        maxPoints: Int = 200_000,
        minDepth: Float = 0.1,
        maxDepth: Float = 8.0
    ) -> Data {
        let floats = process(
            depthMap: depthMap,
            confidenceMap: confidenceMap,
            cameraImage: cameraImage,
            cameraIntrinsics: cameraIntrinsics,
            imageResolution: imageResolution,
            maxPoints: maxPoints,
            minDepth: minDepth,
            maxDepth: maxDepth
        )
        var count = Int32(floats.count / 6)
        var data = Data(bytes: &count, count: 4)
        floats.withUnsafeBytes { data.append(contentsOf: $0) }
        return data
    }

    // MARK: - Core algorithm

    static func process(
        depthMap: CVPixelBuffer,
        confidenceMap: CVPixelBuffer?,
        cameraImage: CVPixelBuffer,
        cameraIntrinsics: simd_float3x3,
        imageResolution: CGSize,
        maxPoints: Int,
        minDepth: Float,
        maxDepth: Float
    ) -> [Float] {
        let depthWidth  = CVPixelBufferGetWidth(depthMap)
        let depthHeight = CVPixelBufferGetHeight(depthMap)
        let imgWidth    = Int(imageResolution.width)
        let imgHeight   = Int(imageResolution.height)

        // Camera intrinsics are in full-image-resolution pixel coordinates
        // Column 0 = [fx, 0, 0], Column 1 = [0, fy, 0], Column 2 = [cx, cy, 1]
        let fx = cameraIntrinsics[0][0]
        let fy = cameraIntrinsics[1][1]
        let cx = cameraIntrinsics[2][0]
        let cy = cameraIntrinsics[2][1]

        let scaleX = Float(imgWidth)  / Float(depthWidth)
        let scaleY = Float(imgHeight) / Float(depthHeight)

        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        if let cm = confidenceMap { CVPixelBufferLockBaseAddress(cm, .readOnly) }
        CVPixelBufferLockBaseAddress(cameraImage, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            if let cm = confidenceMap { CVPixelBufferUnlockBaseAddress(cm, .readOnly) }
            CVPixelBufferUnlockBaseAddress(cameraImage, .readOnly)
        }

        let depthPtr = CVPixelBufferGetBaseAddress(depthMap)!
            .bindMemory(to: Float32.self, capacity: depthWidth * depthHeight)
        let depthStride = CVPixelBufferGetBytesPerRow(depthMap) / MemoryLayout<Float32>.size

        let confPtr: UnsafeMutablePointer<UInt8>?
        let confStride: Int
        if let cm = confidenceMap {
            confPtr = CVPixelBufferGetBaseAddress(cm)!
                .bindMemory(to: UInt8.self, capacity: depthWidth * depthHeight)
            confStride = CVPixelBufferGetBytesPerRow(cm)
        } else {
            confPtr = nil
            confStride = 0
        }

        // Camera image YCbCr planes
        let yPlane = CVPixelBufferGetBaseAddressOfPlane(cameraImage, 0)!
            .bindMemory(to: UInt8.self, capacity: imgWidth * imgHeight)
        let yStride = CVPixelBufferGetBytesPerRowOfPlane(cameraImage, 0)
        let cbCrPlane = CVPixelBufferGetBaseAddressOfPlane(cameraImage, 1)!
            .bindMemory(to: UInt8.self, capacity: (imgWidth / 2) * (imgHeight / 2) * 2)
        let cbCrStride = CVPixelBufferGetBytesPerRowOfPlane(cameraImage, 1)

        var points = [Float]()
        points.reserveCapacity(min(depthWidth * depthHeight, maxPoints) * 6)

        for row in 0..<depthHeight {
            if points.count / 6 >= maxPoints { break }
            for col in 0..<depthWidth {
                // Confidence filter (0=low 1=medium 2=high); require ≥ medium
                if let cp = confPtr {
                    let conf = cp[row * confStride + col]
                    guard conf >= 1 else { continue }
                }

                let depth = depthPtr[row * depthStride + col]
                guard depth >= minDepth && depth <= maxDepth else { continue }

                // Scale depth pixel to full-image coordinates
                let imgColF = Float(col) * scaleX
                let imgRowF = Float(row) * scaleY

                // Deproject: pixel (u,v) + depth → camera-space 3D point
                // ARKit uses right-handed camera space: +X right, +Y up, -Z forward
                // The standard pinhole model (Z forward) gives:
                //   x = (u - cx) * Z / fx
                //   y = (v - cy) * Z / fy
                let x =  (imgColF - cx) * depth / fx
                let y = -(imgRowF - cy) * depth / fy  // flip Y: pixel row increases downward
                let z = -depth                         // ARKit: camera looks toward -Z

                // Sample colour from YCbCr image
                let clampCol = min(max(Int(imgColF), 0), imgWidth  - 1)
                let clampRow = min(max(Int(imgRowF), 0), imgHeight - 1)

                let yVal = Float(yPlane[clampRow * yStride + clampCol])
                let cbCrIdx = (clampRow / 2) * cbCrStride + (clampCol / 2) * 2
                let cb = Float(cbCrPlane[cbCrIdx])     - 128
                let cr = Float(cbCrPlane[cbCrIdx + 1]) - 128

                let r = clampF((yVal + 1.402 * cr)                       / 255)
                let g = clampF((yVal - 0.344136 * cb - 0.714136 * cr)   / 255)
                let b = clampF((yVal + 1.772 * cb)                       / 255)

                points.append(contentsOf: [x, y, z, r, g, b])

                if points.count / 6 >= maxPoints { break }
            }
        }
        return points
    }

    @inline(__always)
    private static func clampF(_ v: Float) -> Float {
        return max(0, min(1, v))
    }
}
