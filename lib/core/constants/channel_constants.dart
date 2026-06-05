class ChannelConstants {
  ChannelConstants._();

  static const String arSessionChannel = 'com.pointcloud.capture/ar_session';
  static const String pointCloudEventChannel =
      'com.pointcloud.capture/point_cloud_stream';
  static const String metalViewType = 'com.pointcloud.capture/metal_view';

  static String metalViewChannel(int viewId) =>
      'com.pointcloud.capture/metal_view_$viewId';
}
