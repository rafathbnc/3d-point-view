import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/saved_capture.dart';
import '../../../providers/gallery_provider.dart';

class ExportBottomSheet extends ConsumerWidget {
  final SavedCapture capture;

  const ExportBottomSheet({super.key, required this.capture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.onSurfaceSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            capture.name,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${_fmt(capture.pointCount)} points · ${capture.savedAt.toLocal().toString().substring(0, 16)}',
            style: const TextStyle(
              color: AppColors.onSurfaceSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          if (capture.plyPath != null) ...[
            _ExportButton(
              label: 'View in 3D',
              icon: Icons.threed_rotation,
              onTap: (ctx) {
                final router = GoRouter.of(ctx);
                Navigator.of(ctx).pop();
                router.push(AppRouter.captureViewer, extra: capture);
              },
            ),
            const SizedBox(height: 10),
          ],
          if (capture.plyPath != null)
            _ExportButton(
              label: 'Share PLY file',
              icon: Icons.share,
              onTap: (ctx) => _share([capture.plyPath!], ctx),
            ),
          if (capture.xyzPath != null) ...[
            const SizedBox(height: 10),
            _ExportButton(
              label: 'Share XYZ file',
              icon: Icons.share,
              onTap: (ctx) => _share([capture.xyzPath!], ctx),
            ),
          ],
          if (capture.plyPath != null && capture.xyzPath != null) ...[
            const SizedBox(height: 10),
            _ExportButton(
              label: 'Share both files',
              icon: Icons.file_copy_outlined,
              onTap: (ctx) => _share([capture.plyPath!, capture.xyzPath!], ctx),
            ),
          ],
          if (capture.objPath != null) ...[
            const SizedBox(height: 10),
            _ExportButton(
              label: 'Share OBJ file',
              icon: Icons.share,
              onTap: (ctx) => _share([capture.objPath!], ctx),
            ),
          ],
          const SizedBox(height: 10),
          _ExportButton(
            label: 'Edit Name',
            icon: Icons.edit_outlined,
            onTap: (ctx) => _showRenameDialog(ctx, ref),
          ),
          const SizedBox(height: 10),
          _ExportButton(
            label: 'Delete',
            icon: Icons.delete_outline,
            color: AppColors.error,
            onTap: (ctx) => _showDeleteDialog(ctx, ref),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: capture.name);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Edit Name'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final newName = controller.text.trim();
      if (newName.isNotEmpty && newName != capture.name) {
        await ref.read(galleryProvider.notifier).rename(capture.id, newName);
      }
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Capture'),
        content: Text('Delete "${capture.name}"? This cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(galleryProvider.notifier).delete(capture.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _share(List<String> paths, BuildContext ctx) async {
    final files = paths
        .where((p) => File(p).existsSync())
        .map((p) => XFile(p))
        .toList();
    if (files.isEmpty) return;
    final box = ctx.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 100, 10, 10);
    await Share.shareXFiles(files, sharePositionOrigin: origin);
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final void Function(BuildContext) onTap;

  const _ExportButton({
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        onPressed: () => onTap(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
