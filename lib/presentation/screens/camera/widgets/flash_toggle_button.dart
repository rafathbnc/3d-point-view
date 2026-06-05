import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/flash_provider.dart';

class FlashToggleButton extends ConsumerWidget {
  const FlashToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashOn = ref.watch(flashProvider);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => toggleFlash(ref),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: flashOn
              ? AppColors.warning.withValues(alpha: 0.2)
              : AppColors.overlayDark,
          shape: BoxShape.circle,
        ),
        child: Icon(
          flashOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt_slash,
          color: flashOn ? AppColors.warning : AppColors.onSurface,
          size: 22,
        ),
      ),
    );
  }
}
