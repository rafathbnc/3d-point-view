import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../providers/view_transform_provider.dart';

class GestureHandler extends ConsumerStatefulWidget {
  final Widget child;
  final int? metalViewId;
  /// When true (default), double-tap also calls resetAccumulation on the renderer.
  /// Set to false in contexts where points must survive the reset (e.g. capture viewer).
  final bool clearOnDoubleTap;

  const GestureHandler({
    super.key,
    required this.child,
    this.metalViewId,
    this.clearOnDoubleTap = true,
  });

  @override
  ConsumerState<GestureHandler> createState() => _GestureHandlerState();
}

class _GestureHandlerState extends ConsumerState<GestureHandler> {
  double _lastScale = 1.0;
  bool _isPinching = false;
  MethodChannel? _viewChannel;

  @override
  void initState() {
    super.initState();
    _updateChannel(widget.metalViewId);
  }

  @override
  void didUpdateWidget(GestureHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.metalViewId != oldWidget.metalViewId) {
      _updateChannel(widget.metalViewId);
    }
  }

  void _updateChannel(int? id) {
    _viewChannel = id != null
        ? MethodChannel(ChannelConstants.metalViewChannel(id))
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _lastScale = 1.0;
        _isPinching = details.pointerCount > 1;
      },
      onScaleUpdate: (details) {
        final notifier = ref.read(viewTransformProvider.notifier);
        if (_isPinching || details.pointerCount > 1) {
          if (details.scale != 1.0) {
            final scaleDelta = details.scale / _lastScale;
            notifier.applyZoom(scaleDelta);
            _lastScale = details.scale;
          }
          if (details.focalPointDelta != Offset.zero) {
            notifier.applyPan(details.focalPointDelta);
          }
        } else {
          notifier.applyRotation(details.focalPointDelta);
        }
        // Send immediately — no debounce, no Riverpod listener round-trip.
        _viewChannel?.invokeMethod(
          'setTransform',
          ref.read(viewTransformProvider).toMap(),
        );
      },
      onScaleEnd: (_) {
        _isPinching = false;
        _lastScale = 1.0;
      },
      onDoubleTap: () {
        ref.read(viewTransformProvider.notifier).reset();
        if (widget.clearOnDoubleTap) {
          _viewChannel?.invokeMethod('resetAccumulation');
        }
      },
      child: widget.child,
    );
  }
}
