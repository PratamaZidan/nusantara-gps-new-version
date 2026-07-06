import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';

/// Widget pilih icon marker POI.
/// Karena URL icon di server butuh auth (403), tampilkan preview warna
/// berdasarkan nama icon — sesuai dengan warna marker di peta.
class PoiIconPicker extends StatelessWidget {
  final List<String> iconList;
  final String selectedIcon;
  final ResultState loadState;
  final ValueChanged<String> onSelect;

  static const _baseUrl = 'https://lacak.nusantaragps.com/assets/icon/';

  const PoiIconPicker({
    super.key,
    required this.iconList,
    required this.selectedIcon,
    required this.loadState,
    required this.onSelect,
  });

  // Full URL icon dari path relatif
  static String iconUrl(String iconPath) => '$_baseUrl$iconPath';

  // Label singkat dari nama icon
  static String _labelFromIcon(String iconPath) {
    final file = iconPath.split('/').last;
    final name = file
        .replaceAll('marker_', '')
        .replaceAll('marker', '')
        .replaceAll('.png', '');
    if (name.isEmpty) return 'Default';
    // pisahkan huruf kecil (warna) dan huruf besar (suffix A/B)
    final match = RegExp(r'([a-zA-Z]+)([A-B]?)').firstMatch(name);
    if (match != null) {
      final color = match.group(1) ?? '';
      final suffix = match.group(2) ?? '';
      if (color.isEmpty) return suffix.isEmpty ? 'Default' : suffix;
      final label = '${color[0].toUpperCase()}${color.substring(1)}';
      return suffix.isNotEmpty ? '$label $suffix' : label;
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ICON MARKER', style: AppTextTheme.bodySmall),
        const SizedBox(height: 8),
        switch (loadState) {
          ResultState.loading => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            ),
          _ => iconList.isEmpty
              ? _buildSinglePreview()
              : _buildGrid(),
        },
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: iconList.length,
      itemBuilder: (_, i) {
        final icon = iconList[i];
        final isSelected = icon == selectedIcon;

        return GestureDetector(
          onTap: () => onSelect(icon),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? AppColorTheme.green100 : AppColorTheme.gray100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColorTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Image.network(
                    iconUrl(icon),
                    fit: BoxFit.contain,
                    cacheWidth: 64,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.location_on,
                      color: Colors.grey,
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(height: 2),
                Text(
                  _labelFromIcon(icon),
                  style: TextStyle(
                    fontSize: 8,
                    color: isSelected ? AppColorTheme.primary : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSinglePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorTheme.gray100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColorTheme.gray300),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Image.network(
              iconUrl(selectedIcon),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.location_on,
                color: Colors.grey,
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Icon: ${_labelFromIcon(selectedIcon)}',
            style: AppTextTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}