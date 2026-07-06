import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/app/constant.dart';

class VehicleStatusWidget extends StatelessWidget {
  final VehicleStatus status;
  const VehicleStatusWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: status.secondaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: AppTextTheme.bodyMedium.copyWith(color: status.color),
      ),
    );
  }
}
