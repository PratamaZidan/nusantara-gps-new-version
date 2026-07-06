import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';

class CustomSnackbarWithStack extends StatelessWidget {
  final String message;
  final Widget? trailling;
  final Color color;
  const CustomSnackbarWithStack({
    super.key,
    required this.message,
    this.trailling,
    this.color = AppColorTheme.red,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextTheme.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
          if (trailling != null) trailling!,
        ],
      ),
    );
  }
}
