import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/domain/entities/geofence_draw_mode.dart';

class GeofenceDrawToolbar extends StatelessWidget {
  final GeofenceDrawMode selected;
  final ValueChanged<GeofenceDrawMode> onModeChanged;

  const GeofenceDrawToolbar({
    super.key,
    required this.selected,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolBtn(icon: Icons.pan_tool_outlined, tooltip: 'Geser peta', mode: GeofenceDrawMode.pan, selected: selected, onTap: onModeChanged),
          _ToolBtn(icon: Icons.crop_square_rounded, tooltip: 'Kotak', mode: GeofenceDrawMode.rectangle, selected: selected, onTap: onModeChanged),
          _ToolBtn(icon: Icons.circle_outlined, tooltip: 'Lingkaran', mode: GeofenceDrawMode.circle, selected: selected, onTap: onModeChanged),
          _ToolBtn(icon: Icons.polyline_outlined, tooltip: 'Polygon', mode: GeofenceDrawMode.polygon, selected: selected, onTap: onModeChanged),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final GeofenceDrawMode mode;
  final GeofenceDrawMode selected;
  final ValueChanged<GeofenceDrawMode> onTap;

  const _ToolBtn({
    required this.icon,
    required this.tooltip,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected == mode;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => onTap(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? AppColorTheme.primary.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: isActive ? Border.all(color: AppColorTheme.primary, width: 1.5) : null,
          ),
          child: Icon(
            icon,
            size: 19,
            color: isActive ? AppColorTheme.primary : AppColorTheme.gray500,
          ),
        ),
      ),
    );
  }
}