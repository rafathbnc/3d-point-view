import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/accumulating_provider.dart';
import '../../providers/ar_session_provider.dart';
import '../../providers/capture_provider.dart';
import '../../providers/device_capability_provider.dart';
import '../../providers/background_mode_provider.dart';
import '../../providers/point_cloud_color_mode_provider.dart';
import '../../providers/point_size_provider.dart';
import '../../providers/view_transform_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import 'widgets/no_lidar_banner.dart';
import 'widgets/pc_stats_overlay.dart';
import 'widgets/point_cloud_view.dart';

class PointCloudScreen extends ConsumerStatefulWidget {
  const PointCloudScreen({super.key});

  @override
  ConsumerState<PointCloudScreen> createState() => _PointCloudScreenState();
}

class _PointCloudScreenState extends ConsumerState<PointCloudScreen> {
  late final ARSessionNotifier _arNotifier;
  late final ViewTransformNotifier _transformNotifier;
  late final StateController<int> _colorModeController;
  late final StateController<bool> _accumulatingController;

  @override
  void initState() {
    super.initState();
    _arNotifier = ref.read(arSessionProvider.notifier);
    _transformNotifier = ref.read(viewTransformProvider.notifier);
    _colorModeController = ref.read(pointCloudColorModeProvider.notifier);
    _accumulatingController = ref.read(accumulatingProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _arNotifier.start();
    });
  }

  @override
  void dispose() {
    _arNotifier.stop();
    _transformNotifier.reset();
    Future<void>(() {
      _colorModeController.state = 0;
      _accumulatingController.state = false;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capability = ref.watch(deviceCapabilityProvider);
    final hasLiDAR = capability.whenOrNull(data: (c) => c.hasLiDAR) ?? false;
    final sessionState = ref.watch(arSessionProvider);
    final captureState = ref.watch(captureProvider);
    final colorMode = ref.watch(pointCloudColorModeProvider);
    final pointSize = ref.watch(pointSizeProvider);
    final bgDark = ref.watch(bgDarkProvider);
    final accumulating = ref.watch(accumulatingProvider);

    final isLoading = sessionState.status == ARSessionStatus.starting;
    final isSaving = captureState.status == CaptureStatus.capturing ||
        captureState.status == CaptureStatus.saving;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Point cloud renderer or no-LiDAR message
          if (hasLiDAR || !capability.hasValue)
            const PointCloudView()
          else
            const NoLiDARBanner(),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Close button
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
                const SizedBox(width: 8),
                // Double-tap hint
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.overlayDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Double-tap to reset',
                        style: TextStyle(
                          color: AppColors.onSurfaceSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Background toggle (moon)
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
                      color: bgDark
                          ? AppColors.onSurface
                          : AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Color mode toggle (top-right)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _colorModeController.state =
                      colorMode == 0 ? 1 : 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorMode == 1
                          ? AppColors.pointCloudActive.withValues(alpha: 0.25)
                          : AppColors.overlayDark,
                      shape: BoxShape.circle,
                      border: colorMode == 1
                          ? Border.all(
                              color: AppColors.pointCloudActive, width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      Icons.gradient,
                      color: colorMode == 1
                          ? AppColors.pointCloudActive
                          : AppColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // FPS + point count stats
          if (hasLiDAR) const PCStatsOverlay(),

          // Point size slider
          if (hasLiDAR)
            Positioned(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 120,
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
                        inactiveTrackColor: AppColors.onSurfaceSecondary.withValues(alpha: 0.4),
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

          // Bottom capture button
          if (hasLiDAR)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 32,
              child: Center(
                child: GestureDetector(
                  onTap: isSaving || accumulating
                      ? null
                      : () => ref
                          .read(captureProvider.notifier)
                          .captureAndSave(),
                  onLongPressStart: isSaving
                      ? null
                      : (_) => _accumulatingController.state = true,
                  onLongPressEnd: (_) {
                    if (_accumulatingController.state) {
                      _accumulatingController.state = false;
                      ref.read(captureProvider.notifier).captureAndSave();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: accumulating ? 84 : 72,
                    height: accumulating ? 84 : 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accumulating
                          ? AppColors.error.withValues(alpha: 0.25)
                          : AppColors.pointCloudActive.withValues(alpha: 0.15),
                      border: Border.all(
                        color: accumulating
                            ? AppColors.error
                            : AppColors.pointCloudActive,
                        width: accumulating ? 3.5 : 2.5,
                      ),
                    ),
                    child: isSaving
                        ? const CupertinoActivityIndicator(
                            color: AppColors.pointCloudActive)
                        : Icon(
                            accumulating ? Icons.fiber_manual_record : Icons.view_in_ar,
                            color: accumulating
                                ? AppColors.error
                                : AppColors.pointCloudActive,
                            size: 32,
                          ),
                  ),
                ),
              ),
            ),

          if (isLoading)
            const LoadingOverlay(message: 'Initialising LiDAR...'),

          // Save success toast
          if (captureState.status == CaptureStatus.done)
            Positioned(
              bottom: 120,
              left: 32,
              right: 32,
              child: _SuccessToast(
                onDismiss: () =>
                    ref.read(captureProvider.notifier).reset(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuccessToast extends StatelessWidget {
  final VoidCallback onDismiss;
  const _SuccessToast({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Point cloud saved!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
