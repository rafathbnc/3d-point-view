import Foundation

/// Writes a binary PLY file from an interleaved [x,y,z,r,g,b,...] Float32 array.
///
/// Format: binary_little_endian 1.0
/// Vertex layout: 3×Float32 (xyz) + 3×UInt8 (rgb) = 15 bytes per vertex
class PLYExporter {
    static func export(points: [Float], to url: URL) throws {
        let count = points.count / 6
        var header = ""
        header += "ply\r\n"
        header += "format binary_little_endian 1.0\r\n"
        header += "element vertex \(count)\r\n"
        header += "property float x\r\n"
        header += "property float y\r\n"
        header += "property float z\r\n"
        header += "property uchar red\r\n"
        header += "property uchar green\r\n"
        header += "property uchar blue\r\n"
        header += "end_header\r\n"

        var data = header.data(using: .ascii)!
        // 15 bytes per vertex: 3×float32 + 3×uint8
        var vertex = Data(count: 15)
        for i in stride(from: 0, to: points.count, by: 6) {
            var x = points[i],     y = points[i + 1], z = points[i + 2]
            let r = UInt8(min(max(points[i + 3], 0), 1) * 255)
            let g = UInt8(min(max(points[i + 4], 0), 1) * 255)
            let b = UInt8(min(max(points[i + 5], 0), 1) * 255)
            withUnsafeBytes(of: &x) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &y) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &z) { data.append(contentsOf: $0) }
            data.append(contentsOf: [r, g, b])
        }
        try data.write(to: url, options: .atomic)
    }
}
