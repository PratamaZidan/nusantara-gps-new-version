import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';

class InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final String text;

  const InfoTile({
    super.key,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}