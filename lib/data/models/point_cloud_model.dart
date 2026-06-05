import 'dart:typed_data';
import 'package:vector_math/vector_math_64.dart';
import '../../domain/entities/point_cloud.dart';

class PointCloudModel extends PointCloud {
  const PointCloudModel({
    required super.points,
    required super.pointCount,
    required super.capturedAt,
    required super.cameraTransform,
  });

  // Wire format from Swift:
  // Bytes 0-3  : Int32 (little-endian) point count N
  // Bytes 4-end: Float32[N*6] interleaved [x,y,z,r,g,b,...]
  factory PointCloudModel.fromBytes(Uint8List bytes) {
    if (bytes.length < 4) {
      return PointCloudModel(
        points: Float32List(0),
        pointCount: 0,
        capturedAt: DateTime.now(),
        cameraTransform: Matrix4.identity(),
      );
    }
    final bd = ByteData.sublistView(bytes);
    final count = bd.getInt32(0, Endian.little);
    final expectedBytes = 4 + count * 6 * 4;
    if (bytes.length < expectedBytes || count <= 0) {
      return PointCloudModel(
        points: Float32List(0),
        pointCount: 0,
        capturedAt: DateTime.now(),
        cameraTransform: Matrix4.identity(),
      );
    }
    // sublist() always produces offsetInBytes==0, satisfying Float32List's 4-byte alignment requirement.
    final floatBytes = bytes.sublist(4, expectedBytes);
    final floats = Float32List.view(floatBytes.buffer, 0, count * 6);
    return PointCloudModel(
      points: floats,
      pointCount: count,
      capturedAt: DateTime.now(),
      cameraTransform: Matrix4.identity(),
    );
  }
}
