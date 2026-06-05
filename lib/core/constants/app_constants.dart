class AppConstants {
  AppConstants._();

  static const int maxPointsPerFrame = 200000;
  static const int pointCloudFrameRateHz = 15;
  static const double minDepthMetres = 0.1;
  static const double maxDepthMetres = 8.0;
  static const double metalPointSizePx = 3.0;
  static const double gestureRotationSensitivity = 0.01;
  static const double gesturePanSensitivity = 0.002;
  static const double gestureZoomMin = 0.2;
  static const double gestureZoomMax = 10.0;
  static const int gestureDebounceMs = 8;
  static const String capturesDirectoryName = 'PointCloudCaptures';
  static const String metadataFileName = 'captures.json';
}
