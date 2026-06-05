import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class PlyResult {
  final Uint8List wireData;
  /// Suggested zoom value so the point cloud fills the viewport.
  final double suggestedZoom;

  const PlyResult({required this.wireData, required this.suggestedZoom});
}

/// Reads a binary-little-endian PLY file produced by PLYExporter.swift and
/// returns the Metal wire format: 4-byte Int32 count + Float32[N×6] (xyzrgb, rgb ∈ [0,1]).
/// Points are centered at the cloud centroid so the Metal renderer's
/// fixed-eye MVP always frames the cloud regardless of capture distance.
class PlyReader {
  static Future<PlyResult?> readAsWireFormat(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    return compute(_parse, bytes);
  }

  static PlyResult? _parse(Uint8List bytes) {
    // Locate end_header marker
    const markerStr = 'end_header';
    int dataStart = -1;
    outer:
    for (int i = 0; i <= bytes.length - markerStr.length; i++) {
      for (int j = 0; j < markerStr.length; j++) {
        if (bytes[i + j] != markerStr.codeUnitAt(j)) continue outer;
      }
      dataStart = i + markerStr.length;
      while (dataStart < bytes.length &&
          (bytes[dataStart] == 0x0D || bytes[dataStart] == 0x0A)) {
        dataStart++;
      }
      break;
    }
    if (dataStart < 0) return null;

    // Parse vertex count from header text
    final headerText = String.fromCharCodes(bytes.sublist(0, dataStart));
    int vertexCount = 0;
    for (final line in headerText.split('\n')) {
      final t = line.trim();
      if (t.startsWith('element vertex ')) {
        vertexCount = int.tryParse(t.substring(15).trim()) ?? 0;
        break;
      }
    }
    if (vertexCount <= 0) return null;

    // PLY format: 3×float32 xyz (12 bytes) + 3×uint8 rgb (3 bytes) = 15 bytes/vertex
    const srcBytesPerVertex = 15;
    if (bytes.length < dataStart + vertexCount * srcBytesPerVertex) return null;

    final srcView = bytes.buffer.asByteData(bytes.offsetInBytes);

    // --- Pass 1: compute centroid ---
    double sumX = 0, sumY = 0, sumZ = 0;
    int src = dataStart;
    for (int i = 0; i < vertexCount; i++) {
      sumX += srcView.getFloat32(src,     Endian.little);
      sumY += srcView.getFloat32(src + 4, Endian.little);
      sumZ += srcView.getFloat32(src + 8, Endian.little);
      src += srcBytesPerVertex;
    }
    final cx = sumX / vertexCount;
    final cy = sumY / vertexCount;
    final cz = sumZ / vertexCount;

    // --- Pass 2: compute bounding radius from centroid ---
    double maxR2 = 0;
    src = dataStart;
    for (int i = 0; i < vertexCount; i++) {
      final dx = srcView.getFloat32(src,     Endian.little) - cx;
      final dy = srcView.getFloat32(src + 4, Endian.little) - cy;
      final dz = srcView.getFloat32(src + 8, Endian.little) - cz;
      final r2 = dx * dx + dy * dy + dz * dz;
      if (r2 > maxR2) maxR2 = r2;
      src += srcBytesPerVertex;
    }
    final radius = math.sqrt(maxR2).clamp(0.1, double.infinity);

    // Eye distance: keep bounding sphere inside 60° fov with small margin.
    // eyeDist = 4.0 / zoom  →  zoom = 4.0 / eyeDist
    // eyeDist = radius / tan(30°) * 1.2  (20% margin)
    final eyeDist = radius / math.tan(30.0 * math.pi / 180.0) * 1.2;
    final suggestedZoom = (4.0 / eyeDist).clamp(0.05, 20.0);

    // --- Pass 3: build centered wire format ---
    final out = ByteData(4 + vertexCount * 24);
    out.setInt32(0, vertexCount, Endian.little);

    src = dataStart;
    int dst = 4;
    for (int i = 0; i < vertexCount; i++) {
      // xyz — centered at origin
      out.setFloat32(dst,      srcView.getFloat32(src,     Endian.little) - cx, Endian.little); dst += 4;
      out.setFloat32(dst,      srcView.getFloat32(src + 4, Endian.little) - cy, Endian.little); dst += 4;
      out.setFloat32(dst,      srcView.getFloat32(src + 8, Endian.little) - cz, Endian.little); dst += 4;
      // rgb — uint8 [0,255] → float32 [0,1]
      out.setFloat32(dst,      bytes[src + 12] / 255.0, Endian.little); dst += 4;
      out.setFloat32(dst,      bytes[src + 13] / 255.0, Endian.little); dst += 4;
      out.setFloat32(dst,      bytes[src + 14] / 255.0, Endian.little); dst += 4;
      src += srcBytesPerVertex;
    }

    return PlyResult(
      wireData: out.buffer.asUint8List(),
      suggestedZoom: suggestedZoom,
    );
  }
}
