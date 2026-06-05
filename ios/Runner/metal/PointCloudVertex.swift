import simd

/// Uniform data sent to the Metal vertex shader each frame.
struct Uniforms {
    var mvp: simd_float4x4  // 64 bytes
    var pointSize: Float    //  4 bytes
    var colorMode: Int32    //  4 bytes — 0=camera RGB, 1=depth rainbow
}

// MARK: - Matrix helpers

extension simd_float4x4 {
    static func perspective(fovYRadians: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let tanHalfFov = tan(fovYRadians / 2)
        var m = simd_float4x4(0)
        m[0][0] = 1 / (aspect * tanHalfFov)
        m[1][1] = 1 / tanHalfFov
        m[2][2] = -(far + near) / (far - near)
        m[2][3] = -1
        m[3][2] = -(2 * far * near) / (far - near)
        return m
    }

    static func translation(_ x: Float, _ y: Float, _ z: Float) -> simd_float4x4 {
        var m = matrix_identity_float4x4
        m[3] = simd_float4(x, y, z, 1)
        return m
    }

    static func rotationX(_ angle: Float) -> simd_float4x4 {
        var m = matrix_identity_float4x4
        m[1][1] =  cos(angle)
        m[1][2] =  sin(angle)
        m[2][1] = -sin(angle)
        m[2][2] =  cos(angle)
        return m
    }

    static func rotationY(_ angle: Float) -> simd_float4x4 {
        var m = matrix_identity_float4x4
        m[0][0] =  cos(angle)
        m[0][2] = -sin(angle)
        m[2][0] =  sin(angle)
        m[2][2] =  cos(angle)
        return m
    }
}
