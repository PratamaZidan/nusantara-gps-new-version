import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';

enum AppButtonState { enabled, disabled, loading }

class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final bool isSecondary;
  final Widget? icon;
  final Gradient? gradient;

  const AppButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.gradient,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    final Widget buttonContent = (isLoading)
        ? const SizedBox(
            height: 24.0,
            width: 24.0,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
        : Text(label);

    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled
            ? (gradient ??
                (isSecondary
                    ? AppColorTheme.secondaryGradient
                    : AppColorTheme.defautGradient))
            : null,
        borderRadius: BorderRadius.circular(8),
        color: isEnabled ? null : AppColorTheme.gray200,
      ),
      child: ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColorTheme.gray400,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          minimumSize: const Size(double.infinity, 44),
        ),
        label: buttonContent,
        iconAlignment: IconAlignment.end,
        icon: icon,
      ),
    );
  }
}
