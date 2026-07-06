import 'package:flutter/material.dart';

import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';

class ProfileItemWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData iconData;

  const ProfileItemWidget({
    super.key,
    required this.title,
    required this.value,
    required this.iconData,
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
          leading: Icon(
            iconData,
            color: AppColorTheme.green600,
          ),
          title: Text(
            title,
            style: AppTextTheme.bodySmall.copyWith(
              color: AppColorTheme.gray400,
            ),
          ),
          subtitle: Text(
            value,
            style: AppTextTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}