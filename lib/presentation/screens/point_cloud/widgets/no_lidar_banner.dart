import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NoLiDARBanner extends StatelessWidget {
  const NoLiDARBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sensors_off, size: 56, color: AppColors.warning),
            const SizedBox(height: 16),
            const Text(
              '3D Point Cloud requires a LiDAR-enabled device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Compatible devices: iPhone 12 Pro and newer, iPad Pro with LiDAR.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onSurfaceSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
