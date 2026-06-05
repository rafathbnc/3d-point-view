import 'dart:typed_data';
import 'point_cloud.dart';

class CapturedFrame {
  final Uint8List rgbaImage;
  final int imageWidth;
  final int imageHeight;
  final PointCloud pointCloud;
  final DateTime timestamp;

  const CapturedFrame({
    required this.rgbaImage,
    required this.imageWidth,
    required this.imageHeight,
    required this.pointCloud,
    required this.timestamp,
  });
}
