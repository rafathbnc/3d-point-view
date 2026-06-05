import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/point_cloud_provider.dart';

class PCStatsOverlay extends ConsumerStatefulWidget {
  const PCStatsOverlay({super.key});

  @override
  ConsumerState<PCStatsOverlay> createState() => _PCStatsOverlayState();
}

class _PCStatsOverlayState extends ConsumerState<PCStatsOverlay> {
  int _fps = 0;
  int _frameCount = 0;
  late Timer _fpsTimer;

  @override
  void initState() {
    super.initState();
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _fps = _frameCount;
        _frameCount = 0;
      });
    });
  }

  @override
  void dispose() {
    _fpsTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Count frames
    ref.listen(pointCloudStreamProvider, (_, next) {
      if (next.hasValue) _frameCount++;
    });

    final pointCount = ref.watch(pointCountProvider);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.overlayDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_fps FPS',
              style: const TextStyle(
                color: AppColors.pointCloudActive,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
            Text(
              '${_formatCount(pointCount)} pts',
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 12,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
