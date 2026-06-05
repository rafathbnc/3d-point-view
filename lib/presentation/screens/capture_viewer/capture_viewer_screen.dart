import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/channel_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/ply_reader.dart';
import '../../../domain/entities/saved_capture.dart';
import '../../providers/background_mode_provider.dart';
import '../../providers/gallery_provider.dart';
import '../../providers/point_size_provider.dart';
import '../../providers/view_transform_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../point_cloud/widgets/gesture_handler.dart';

class CaptureViewerScreen extends ConsumerStatefulWidget {
  final SavedCapture capture;

  const CaptureViewerScreen({super.key, required this.capture});

  @override
  ConsumerState<CaptureViewerScreen> createState() =>
      _CaptureViewerScreenState();
}

class _CaptureViewerScreenState extends ConsumerState<CaptureViewerScreen> {
  int? _viewId;
  MethodChannel? _viewChannel;
  bool _loading = true;
  String? _errorMessage;
  late final ViewTransformNotifier _transformNotifier;

  @override
  void initState() {
    super.initState();
    _transformNotifier = ref.read(viewTransformProvider.notifier);
    // Rotation is pushed to the renderer in _onPlatformViewCreated once the
    // channel exists, so no postFrameCallback needed here.
  }

  @override
  void dispose() {
    _transformNotifier.reset();
    super.dispose();
  }

  Future<void> _onPlatformViewCreated(int id) async {
    _viewId = id;
    _viewChannel = MethodChannel(ChannelConstants.metalViewChannel(id));
    if (mounted) setState(() {});

    try {
      // Clear any points left over from a previous live scan session.
      await _viewChannel?.invokeMethod('resetAccumulation');

      // Apply the oblique starting angle directly — don't read from provider
      // since the postFrameCallback that sets it may not have fired yet.
      final plyPath = widget.capture.plyPath;
      if (plyPath == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMessage = 'No PLY file for this capture.';
          });
        }
        return;
      }

      final result = await PlyReader.readAsWireFormat(plyPath);
      if (!mounted) return;

      if (result == null) {
        setState(() {
          _loading = false;
          _errorMessage = 'Could not read PLY file.';
        });
        return;
      }

      // Use auto-fit zoom so the whole cloud is visible, plus oblique angle.
      const double initRotX = 0.35;
      const double initRotY = 0.45;
      _transformNotifier.setRotation(initRotX, initRotY);
      await _viewChannel?.invokeMethod('setTransform', {
        'rotX': initRotX,
        'rotY': initRotY,
        'zoom': result.suggestedZoom,
        'panX': 0.0,
        'panY': 0.0,
      });

      await _viewChannel?.invokeMethod('updatePointCloud', result.wireData);
      if (mounted) setState(() => _loading = false);

      // Capture a Metal-rendered thumbnail after the first frame settles.
      Future.delayed(const Duration(milliseconds: 700), _takeSnapshot);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load: $e';
        });
      }
    }
  }

  Future<void> _takeSnapshot() async {
    if (!mounted || _viewChannel == null) return;
    try {
      final result = await _viewChannel!.invokeMethod<dynamic>('snapshot');
      if (result == null || !mounted) return;
      Uint8List jpegBytes;
      if (result is Uint8List) {
        jpegBytes = result;
      } else if (result is List) {
        jpegBytes = Uint8List.fromList(result.cast<int>());
      } else {
        return;
      }
      await File(widget.capture.thumbnailPath).writeAsBytes(jpegBytes);
      if (mounted) {
        ref.read(galleryProvider.notifier).refresh();
      }
    } catch (_) {
      // snapshot is best-effort — silently ignore
    }
  }

  Future<void> _shareCapture() async {
    final capture = widget.capture;
    final paths = [capture.plyPath, capture.xyzPath].whereType<String>();
    final files = paths
        .where((p) => File(p).existsSync())
        .map((p) => XFile(p))
        .toList();
    if (files.isEmpty) return;
    await Share.shareXFiles(files);
  }

  @override
  Widget build(BuildContext context) {
    final pts = widget.capture.pointCount;
    final ptsLabel =
        pts >= 1000 ? '${(pts / 1000).toStringAsFixed(1)}k pts' : '$pts pts';

    final pointSize = ref.watch(pointSizeProvider);
    final bgDark = ref.watch(bgDarkProvider);

    ref.listen(pointSizeProvider, (_, size) {
      _viewChannel?.invokeMethod('setPointSize', size);
    });
    ref.listen(bgDarkProvider, (_, dark) {
      _viewChannel?.invokeMethod('setBackground', dark);
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureHandler(
            metalViewId: _viewId,
            clearOnDoubleTap: false,
            child: UiKitView(
              viewType: ChannelConstants.metalViewType,
              creationParams: const {'mode': 'pointcloud'},
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onPlatformViewCreated,
            ),
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.overlayDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: AppColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.capture.name,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      ref.read(bgDarkProvider.notifier).state = !bgDark,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgDark
                          ? AppColors.overlayDark
                          : AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      bgDark ? Icons.brightness_3 : Icons.wb_sunny,
                      color: bgDark ? AppColors.onSurface : AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _shareCapture,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.overlayDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.share,
                      color: AppColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats HUD
          Positioned(
            top: MediaQuery.of(context).padding.top + 52,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.overlayDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ptsLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Text(
                    'Double-tap to reset',
                    style: TextStyle(
                      color: AppColors.onSurfaceSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Point size slider
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Row(
              children: [
                const Icon(Icons.grain, color: AppColors.onSurfaceSecondary, size: 14),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor:
                          AppColors.onSurfaceSecondary.withValues(alpha: 0.4),
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: pointSize,
                      min: 1.0,
                      max: 10.0,
                      onChanged: (v) =>
                          ref.read(pointSizeProvider.notifier).state = v,
                    ),
                  ),
                ),
                const Icon(Icons.grain, color: AppColors.onSurface, size: 20),
              ],
            ),
          ),

          if (_loading) const LoadingOverlay(message: 'Loading point cloud…'),

          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
