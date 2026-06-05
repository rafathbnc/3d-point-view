import 'dart:typed_data';
import 'package:vector_math/vector_math_64.dart';

class PointCloud {
  // Interleaved: [x, y, z, r, g, b, x, y, z, r, g, b, ...]
  // r/g/b are normalised floats in [0, 1]
  final Float32List points;
  final int pointCount;
  final DateTime capturedAt;
  final Matrix4 cameraTransform;

  const PointCloud({
    required this.points,
    required this.pointCount,
    required this.capturedAt,
    required this.cameraTransform,
  });
}
