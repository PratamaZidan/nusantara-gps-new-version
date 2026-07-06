import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/data/models/geofence_model.dart';

class GeofenceCard extends StatelessWidget {
  final GeofenceModel item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GeofenceCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  IconData _shapeIcon(String geoType) {
    switch (geoType) {
      case '1': return Icons.circle_outlined;
      case '2': return Icons.crop_square_rounded;
      default: return Icons.pentagon_outlined;
    }
  }

  String _shapeLabel(String geoType, double? radius) {
    switch (geoType) {
      case '1': final r = radius != null ? '${radius.toStringAsFixed(0)}m' : '';
        return 'Lingkaran $r';
      case '2': return 'Kotak';
      default: return 'Polygon';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColorTheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isSelected ? 30 : 15),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ikon geofence
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColorTheme.primary.withAlpha(20)
                    : Colors.grey.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fence_rounded,
                color: isSelected ? AppColorTheme.primary : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Info teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: AppTextTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColorTheme.primary : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Jenis Alert
                      Icon(
                        item.inout == '1'
                            ? Icons.login_rounded
                            : Icons.logout_rounded,
                        size: 12,
                        color: item.inout == '1'
                            ? Colors.green.shade600
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.inout == '1' ? 'Masuk' : 'Keluar',
                        style: AppTextTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: item.inout == '1'
                              ? Colors.green.shade600
                              : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Tipe area
                      Icon(
                        _shapeIcon(item.geoType),
                        size: 12,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _shapeLabel(item.geoType, item.radiusMeters),
                        style: AppTextTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tombol Edit & Delete
            if (onEdit != null || onDelete != null) ...[
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: Colors.blueGrey,
                  tooltip: 'Edit',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: Colors.red,
                  tooltip: 'Hapus',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}