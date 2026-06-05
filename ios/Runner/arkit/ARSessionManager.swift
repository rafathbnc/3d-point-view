import ARKit
import AVFoundation

/// Manages the ARSession lifecycle and forwards ARFrame callbacks to subscribers.
class ARSessionManager: NSObject, ARSessionDelegate {
    let session = ARSession()

    private let listenersLock = NSLock()
    private var frameListeners: [UUID: (ARFrame) -> Void] = [:]

    /// Set to receive the next frame as a capture result, then cleared.
    private var pendingCaptureCallback: (([String: Any]?, String?) -> Void)?

    // MARK: - Frame listener subscriptions

    @discardableResult
    func addFrameListener(_ callback: @escaping (ARFrame) -> Void) -> UUID {
        let id = UUID()
        listenersLock.lock()
        frameListeners[id] = callback
        listenersLock.unlock()
        return id
    }

    func removeFrameListener(_ id: UUID) {
        listenersLock.lock()
        frameListeners.removeValue(forKey: id)
        listenersLock.unlock()
    }

    // MARK: - Session control

    func startSession(completion: @escaping (String?) -> Void) {
        guard ARWorldTrackingConfiguration.isSupported else {
            completion("ARWorldTracking is not supported on this device")
            return
        }

        let config = ARWorldTrackingConfiguration()

        // Request scene depth (LiDAR) if available
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
                config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
            } else {
                config.frameSemantics = [.sceneDepth]
            }
        }

        config.isAutoFocusEnabled = true
        session.delegate = self
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
        completion(nil)
    }

    func stopSession() {
        session.pause()
    }

    func captureCurrentFrame(completion: @escaping ([String: Any]?, String?) -> Void) {
        // Stored and fulfilled in the next session(_:didUpdate:) call
        pendingCaptureCallback = completion
    }

    func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {}
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        listenersLock.lock()
        let listeners = frameListeners
        listenersLock.unlock()
        for (_, cb) in listeners { cb(frame) }

        if let cb = pendingCaptureCallback {
            pendingCaptureCallback = nil
            let data = serializeFrame(frame)
            cb(data, nil)
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        pendingCaptureCallback?(nil, error.localizedDescription)
        pendingCaptureCallback = nil
    }

    // MARK: - Frame serialisation

    private func serializeFrame(_ frame: ARFrame) -> [String: Any] {
        let pixelBuffer = frame.capturedImage
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        let rgbaBytes = convertYCbCrToRGBA(pixelBuffer: pixelBuffer)

        // Also include current point cloud bytes (using smoothed depth if available)
        let depthSource = frame.smoothedSceneDepth ?? frame.sceneDepth
        let pointBytes: Data
        if let depth = depthSource {
            pointBytes = DepthProcessor.processToData(
                depthMap: depth.depthMap,
                confidenceMap: depth.confidenceMap,
                cameraImage: pixelBuffer,
                cameraIntrinsics: frame.camera.intrinsics,
                imageResolution: frame.camera.imageResolution
            )
        } else {
            pointBytes = Data()
        }

        return [
            "width": width,
            "height": height,
            "imageBytes": FlutterStandardTypedData(bytes: rgbaBytes),
            "pointBytes": FlutterStandardTypedData(bytes: pointBytes)
        ]
    }

    private func convertYCbCrToRGBA(pixelBuffer: CVPixelBuffer) -> Data {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)!
            .bindMemory(to: UInt8.self, capacity: width * height)
        let yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let cbCrPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)!
            .bindMemory(to: UInt8.self, capacity: (width / 2) * (height / 2) * 2)
        let cbCrStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)

        var rgba = [UInt8](repeating: 255, count: width * height * 4)
        for row in 0..<height {
            for col in 0..<width {
                let yVal = Float(yPlane[row * yStride + col])
                let cbCrIdx = (row / 2) * cbCrStride + (col / 2) * 2
                let cb = Float(cbCrPlane[cbCrIdx]) - 128
                let cr = Float(cbCrPlane[cbCrIdx + 1]) - 128
                let r = UInt8(clamp(Int(yVal + 1.402 * cr), 0, 255))
                let g = UInt8(clamp(Int(yVal - 0.344136 * cb - 0.714136 * cr), 0, 255))
                let b = UInt8(clamp(Int(yVal + 1.772 * cb), 0, 255))
                let base = (row * width + col) * 4
                rgba[base] = r; rgba[base + 1] = g; rgba[base + 2] = b; rgba[base + 3] = 255
            }
        }
        return Data(rgba)
    }

    private func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T {
        return min(max(v, lo), hi)
    }
}
