import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';

class AboutItemWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData iconData;
  final VoidCallback? onTap;

  const AboutItemWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: AppColorTheme.gray200,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: AppColorTheme.green100,
            ),
            child: Icon(
              iconData,
              color: AppColorTheme.green600,
            ),
          ),
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: AppTextTheme.bodySmall.copyWith(
              color: AppColorTheme.gray400,
            ),
          ),
        ),
      ),
    );
  }
}