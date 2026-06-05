import 'package:flutter/services.dart';
import '../../core/constants/channel_constants.dart';

class PointCloudEventDataSource {
  static const _eventChannel =
      EventChannel(ChannelConstants.pointCloudEventChannel);

  Stream<Uint8List> get rawStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Uint8List) return event;
      // FlutterStandardTypedData arrives as Uint8List already
      return Uint8List.fromList(event as List<int>);
    });
  }
}
