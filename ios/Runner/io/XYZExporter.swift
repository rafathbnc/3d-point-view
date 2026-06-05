import Foundation

/// Writes an ASCII XYZ file with colour from an interleaved [x,y,z,r,g,b,...] Float32 array.
class XYZExporter {
    static func export(points: [Float], to url: URL, capturedAt: Date = Date()) throws {
        let count = points.count / 6
        let formatter = ISO8601DateFormatter()
        var lines = "# PointCloud Capture - \(formatter.string(from: capturedAt))\r\n"
        lines    += "# Points: \(count)\r\n"
        lines    += "x y z r g b\r\n"

        for i in stride(from: 0, to: points.count, by: 6) {
            let r = Int(min(max(points[i + 3], 0), 1) * 255)
            let g = Int(min(max(points[i + 4], 0), 1) * 255)
            let b = Int(min(max(points[i + 5], 0), 1) * 255)
            lines += String(
                format: "%.6f %.6f %.6f %d %d %d\r\n",
                points[i], points[i + 1], points[i + 2], r, g, b
            )
        }
        try lines.write(to: url, atomically: true, encoding: .ascii)
    }
}
