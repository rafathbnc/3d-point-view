import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/saved_capture.dart';

class CaptureTile extends StatelessWidget {
  final SavedCapture capture;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CaptureTile({
    super.key,
    required this.capture,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            File(capture.thumbnailPath).existsSync()
                ? Image.file(
                    File(capture.thumbnailPath),
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: AppColors.surface,
                    child: const Icon(
                      Icons.view_in_ar,
                      color: AppColors.onSurfaceSecondary,
                      size: 40,
                    ),
                  ),

            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      capture.name,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_formatCount(capture.pointCount)} pts',
                      style: const TextStyle(
                        color: AppColors.onSurfaceSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Format badges
            Positioned(
              top: 6,
              right: 6,
              child: Row(
                children: [
                  if (capture.plyPath != null) _badge('PLY'),
                  if (capture.xyzPath != null) _badge('XYZ'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label) => Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
