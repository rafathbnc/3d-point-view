import 'dart:typed_data';
import 'package:vector_math/vector_math_64.dart';
import '../../domain/entities/captured_frame.dart';
import 'point_cloud_model.dart';

class CapturedFrameModel extends CapturedFrame {
  const CapturedFrameModel({
    required super.rgbaImage,
    required super.imageWidth,
    required super.imageHeight,
    required super.pointCloud,
    required super.timestamp,
  });

  // Raw data map from Swift captureFrame() method channel call.
  // Keys: 'width'(int), 'height'(int), 'imageBytes'(Uint8List),
  //       'pointBytes'(Uint8List — same wire format as PointCloudModel)
  factory CapturedFrameModel.fromMap(Map<String, dynamic> map) {
    final pointBytes = map['pointBytes'] as Uint8List? ?? Uint8List(0);
    final cloud = PointCloudModel.fromBytes(pointBytes);
    return CapturedFrameModel(
      rgbaImage: map['imageBytes'] as Uint8List,
      imageWidth: map['width'] as int,
      imageHeight: map['height'] as int,
      pointCloud: cloud,
      timestamp: DateTime.now(),
    );
  }

  // Fallback when no depth data is present (photo-only capture).
  factory CapturedFrameModel.photoOnly({
    required Uint8List rgbaImage,
    required int width,
    required int height,
  }) {
    return CapturedFrameModel(
      rgbaImage: rgbaImage,
      imageWidth: width,
      imageHeight: height,
      pointCloud: PointCloudModel(
        points: Float32List(0),
        pointCount: 0,
        capturedAt: DateTime.now(),
        cameraTransform: Matrix4.identity(),
      ),
      timestamp: DateTime.now(),
    );
  }
}
