import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: isLoading ? null : onPressed,
      color: backgroundColor ?? AppColors.primary,
      borderRadius: BorderRadius.circular(12),
      child: isLoading
          ? const CupertinoActivityIndicator(color: AppColors.onSurface)
          : Text(
              label,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
