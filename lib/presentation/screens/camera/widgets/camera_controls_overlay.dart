import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/capture_provider.dart';
import '../../../providers/device_capability_provider.dart';
import '../../../providers/gallery_provider.dart';
import 'flash_toggle_button.dart';

class CameraControlsOverlay extends ConsumerWidget {
  const CameraControlsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureState = ref.watch(captureProvider);
    final hasLiDAR =
        ref.watch(deviceCapabilityProvider).whenOrNull(data: (c) => c.hasLiDAR) ?? false;

    final isBusy = captureState.status == CaptureStatus.capturing ||
        captureState.status == CaptureStatus.saving;

    final captureCount = ref
            .watch(galleryProvider)
            .whenOrNull(data: (list) => list.length) ??
        0;

    return Stack(
      children: [
        // Top bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Gallery button with capture count badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _IconCircleButton(
                    icon: Icons.photo_library_outlined,
                    onTap: () => context.push(AppRouter.gallery),
                  ),
                  if (captureCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          captureCount > 99 ? '99+' : '$captureCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              // Right side: flash + 3D mode toggle
              Row(
                children: [
                  const FlashToggleButton(),
                  const SizedBox(width: 10),
                  _3DModeButton(hasLiDAR: hasLiDAR),
                ],
              ),
            ],
          ),
        ),

        // Bottom shutter button
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).padding.bottom + 32,
          child: Center(
            child: GestureDetector(
              onTap: isBusy
                  ? null
                  : () => ref.read(captureProvider.notifier).captureAndSave(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.captureButtonBorder,
                    width: 3,
                  ),
                  color: isBusy
                      ? AppColors.onSurfaceSecondary
                      : Colors.transparent,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: isBusy
                      ? const CupertinoActivityIndicator(
                          color: AppColors.onSurface)
                      : Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.captureButton,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small circle icon button — same style used across overlays.
class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.overlayDark,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.onSurface, size: 20),
      ),
    );
  }
}

/// 3D mode toggle — top-right corner, styled like a camera-switch button.
class _3DModeButton extends StatelessWidget {
  final bool hasLiDAR;
  const _3DModeButton({required this.hasLiDAR});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        if (!hasLiDAR) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('3D Point Cloud requires a LiDAR device.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
        context.push(AppRouter.pointCloud);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasLiDAR
              ? AppColors.pointCloudActive.withValues(alpha: 0.25)
              : AppColors.overlayDark,
          shape: BoxShape.circle,
          border: Border.all(
            color: hasLiDAR
                ? AppColors.pointCloudActive
                : AppColors.onSurfaceSecondary,
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.view_in_ar,
          color: hasLiDAR
              ? AppColors.pointCloudActive
              : AppColors.onSurfaceSecondary,
          size: 20,
        ),
      ),
    );
  }
}
