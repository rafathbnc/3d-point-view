#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float  pointSize [[point_size]];
};

struct Uniforms {
    float4x4 mvp;
    float    pointSize;
    int      colorMode;  // 0 = camera RGB, 1 = depth rainbow
};

// Compact HSV → RGB (IQ's formula)
float3 hsvToRgb(float h, float s, float v) {
    float4 K = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    float3 p = abs(fract(h + K.xyz) * 6.0 - K.www);
    return v * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), s);
}

// Each vertex is 6 consecutive floats in the raw buffer:
//   [0]=x [1]=y [2]=z [3]=r [4]=g [5]=b
// r/g/b are normalised [0,1] floats.
vertex VertexOut point_cloud_vertex(
    uint                   vertexID  [[vertex_id]],
    constant float*        vertices  [[buffer(0)]],
    constant Uniforms&     uniforms  [[buffer(1)]]
) {
    uint base = vertexID * 6;
    float3 pos = float3(vertices[base], vertices[base + 1], vertices[base + 2]);
    float3 col = float3(vertices[base + 3], vertices[base + 4], vertices[base + 5]);

    float3 finalColor;
    if (uniforms.colorMode == 1) {
        // Depth-based rainbow: pos.z is negative (ARKit –Z forward).
        // Map 0.1 m (near) → red,  8.0 m (far) → blue.
        float depth = clamp((-pos.z - 0.1) / 7.9, 0.0, 1.0);
        float hue   = (1.0 - depth) * 0.75; // 0.75 = blue; 0.0 = red
        finalColor  = hsvToRgb(hue, 1.0, 1.0);
    } else {
        finalColor = col; // real camera RGB
    }

    VertexOut out;
    out.position  = uniforms.mvp * float4(pos, 1.0);
    out.color     = float4(finalColor, 1.0);
    out.pointSize = uniforms.pointSize;
    return out;
}

// Discard corners to produce circular point sprites.
fragment float4 point_cloud_fragment(
    VertexOut in             [[stage_in]],
    float2    pointCoord     [[point_coord]]
) {
    float dist = length(pointCoord - float2(0.5));
    if (dist > 0.5) discard_fragment();
    return in.color;
}
