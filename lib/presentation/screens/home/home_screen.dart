import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/device_capability_provider.dart';
import '../../providers/permission_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionProvider.notifier).requestAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final capability = ref.watch(deviceCapabilityProvider);
    final hasLiDAR = capability.whenOrNull(data: (c) => c.hasLiDAR) ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PointCloud Capture',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined,
                color: AppColors.onSurface),
            onPressed: () => context.push(AppRouter.gallery),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview background (dark placeholder until session starts)
          Container(color: AppColors.background),

          // Center logo / instructions
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined,
                    size: 80, color: AppColors.onSurfaceSecondary),
                const SizedBox(height: 16),
                const Text(
                  'Tap SCAN 3D to start LiDAR capture',
                  style: TextStyle(
                    color: AppColors.onSurfaceSecondary,
                    fontSize: 16,
                  ),
                ),
                if (!hasLiDAR && capability.hasValue) ...[
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning, width: 1),
                    ),
                    child: const Text(
                      '3D Point Cloud requires a LiDAR-enabled device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.warning, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom scan button
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (!hasLiDAR && capability.hasValue) {
                    _showNoLiDARSnackBar();
                    return;
                  }
                  context.push(AppRouter.pointCloud);
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasLiDAR
                        ? AppColors.pointCloudActive.withValues(alpha: 0.15)
                        : AppColors.surfaceSecondary,
                    border: Border.all(
                      color: hasLiDAR
                          ? AppColors.pointCloudActive
                          : AppColors.onSurfaceSecondary,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.view_in_ar,
                    color: hasLiDAR
                        ? AppColors.pointCloudActive
                        : AppColors.onSurfaceSecondary,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),

          // Scan label
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: Text(
                'SCAN 3D',
                style: TextStyle(
                  color: hasLiDAR
                      ? AppColors.pointCloudActive
                      : AppColors.onSurfaceSecondary,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoLiDARSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '3D Point Cloud requires a LiDAR-enabled device.',
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
