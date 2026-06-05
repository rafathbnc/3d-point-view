import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/gallery_provider.dart';
import 'widgets/capture_tile.dart';
import 'widgets/export_bottom_sheet.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryAsync = ref.watch(galleryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Captures'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.back, color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onSurface),
            onPressed: () => ref.read(galleryProvider.notifier).refresh(),
          ),
        ],
      ),
      body: galleryAsync.when(
        loading: () => const Center(
          child: CupertinoActivityIndicator(color: AppColors.onSurface),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load captures: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (captures) {
          if (captures.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 64, color: AppColors.onSurfaceSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No captures yet.\nUse 3D Point Cloud mode to capture.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.onSurfaceSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: captures.length,
            itemBuilder: (ctx, i) {
              final capture = captures[i];
              return CaptureTile(
                capture: capture,
                onTap: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ExportBottomSheet(capture: capture),
                ),
                onLongPress: () => _confirmDelete(context, ref, capture.id),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Capture'),
        content: const Text('This will permanently remove the capture and its files.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              ref.read(galleryProvider.notifier).delete(id);
            },
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
