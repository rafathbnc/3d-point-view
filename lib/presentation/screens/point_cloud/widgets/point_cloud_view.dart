import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../providers/accumulating_provider.dart';
import '../../../providers/background_mode_provider.dart';
import '../../../providers/point_cloud_color_mode_provider.dart';
import '../../../providers/point_cloud_provider.dart';
import '../../../providers/point_size_provider.dart';
import 'gesture_handler.dart';

class PointCloudView extends ConsumerStatefulWidget {
  const PointCloudView({super.key});

  @override
  ConsumerState<PointCloudView> createState() => _PointCloudViewState();
}

class _PointCloudViewState extends ConsumerState<PointCloudView> {
  int? _viewId;
  MethodChannel? _viewChannel;
  final _frameBuffer = Queue<Uint8List>();
  static const _kMaxFrames = 3;

  void _onPlatformViewCreated(int id) {
    _viewId = id;
    _viewChannel = MethodChannel(ChannelConstants.metalViewChannel(id));
    setState(() {});
  }

  void _pushPointCloud(Uint8List bytes, {required bool accumulating}) {
    if (accumulating) {
      // Scan mode: just append without clearing — build a dense cloud
      _viewChannel?.invokeMethod('updatePointCloud', bytes);
    } else {
      // Normal mode: rolling 3-frame composite for density + responsiveness
      _frameBuffer.addLast(bytes);
      while (_frameBuffer.length > _kMaxFrames) {
        _frameBuffer.removeFirst();
      }
      _viewChannel?.invokeMethod('resetAccumulation');
      for (final frame in _frameBuffer) {
        _viewChannel?.invokeMethod('updatePointCloud', frame);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Forward color mode changes to native renderer
    ref.listen(pointCloudColorModeProvider, (_, mode) {
      _viewChannel?.invokeMethod('setColorMode', mode);
    });

    ref.listen(pointSizeProvider, (_, size) {
      _viewChannel?.invokeMethod('setPointSize', size);
    });

    ref.listen(bgDarkProvider, (_, dark) {
      _viewChannel?.invokeMethod('setBackground', dark);
    });

    // Forward incoming point cloud frames to native renderer
    final accumulating = ref.watch(accumulatingProvider);
    ref.listen(pointCloudStreamProvider, (_, next) {
      if (next.hasValue && next.value != null) {
        final pts = next.value!.points;
        final count = next.value!.pointCount;
        // Reconstruct wire format: 4-byte count header + float data
        final header = ByteData(4)..setInt32(0, count, Endian.little);
        final buf = Uint8List(4 + pts.lengthInBytes);
        buf.setRange(0, 4, header.buffer.asUint8List());
        buf.setRange(4, buf.length, pts.buffer.asUint8List());
        _pushPointCloud(buf, accumulating: accumulating);
      }
    });

    return GestureHandler(
      metalViewId: _viewId,
      child: UiKitView(
        viewType: ChannelConstants.metalViewType,
        creationParams: const {'mode': 'pointcloud'},
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
    );
  }
}
