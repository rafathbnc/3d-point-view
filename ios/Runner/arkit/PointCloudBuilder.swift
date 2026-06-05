import simd

/// Transforms camera-space points into ARKit world space.
class PointCloudBuilder {
    /// `cameraPoints` is interleaved [x,y,z,r,g,b,...] in camera space.
    /// Returns the same format with xyz transformed to world space.
    static func toWorldSpace(
        cameraPoints: [Float],
        cameraTransform: simd_float4x4
    ) -> [Float] {
        var worldPoints = [Float]()
        worldPoints.reserveCapacity(cameraPoints.count)
        let stride = 6

        var i = 0
        while i < cameraPoints.count {
            let camVec = simd_float4(
                cameraPoints[i],
                cameraPoints[i + 1],
                cameraPoints[i + 2],
                1.0
            )
            let worldVec = cameraTransform * camVec
            worldPoints.append(contentsOf: [
                worldVec.x, worldVec.y, worldVec.z,
                cameraPoints[i + 3],
                cameraPoints[i + 4],
                cameraPoints[i + 5]
            ])
            i += stride
        }
        return worldPoints
    }
}
