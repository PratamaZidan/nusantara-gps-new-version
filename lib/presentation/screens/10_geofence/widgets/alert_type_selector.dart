import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/create/geofence_create_view_model.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/edit/geofence_edit_view_model.dart';

// Untuk Create
class AlertTypeSelector extends StatelessWidget {
  final GeofenceAlertType selected;
  final ValueChanged<GeofenceAlertType> onChanged;

  const AlertTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RadioOpt(
          label: 'Alert saat masuk',
          value: GeofenceAlertType.enter,
          group: selected,
          onChanged: onChanged,
        ),
        const SizedBox(width: 12),
        _RadioOpt(
          label: 'Alert saat keluar',
          value: GeofenceAlertType.exit,
          group: selected,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RadioOpt extends StatelessWidget {
  final String label;
  final GeofenceAlertType value;
  final GeofenceAlertType group;
  final ValueChanged<GeofenceAlertType> onChanged;

  const _RadioOpt({
    required this.label,
    required this.value,
    required this.group,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Radio<GeofenceAlertType>(
            value: value,
            groupValue: group,
            onChanged: (v) => onChanged(v!),
            activeColor: AppColorTheme.primary,
          ),
          Text(label, style: AppTextTheme.bodyMedium),
        ],
      ),
    );
  }
}

// Untuk Edit
class AlertTypeSelectorEdit extends StatelessWidget {
  final GeofenceAlertTypeEdit selected;
  final ValueChanged<GeofenceAlertTypeEdit> onChanged;
  const AlertTypeSelectorEdit({required this.selected, required this.onChanged});
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RadioEdit(label: 'Alert saat masuk', value: GeofenceAlertTypeEdit.enter, group: selected, onChanged: onChanged),
        const SizedBox(width: 12),
        _RadioEdit(label: 'Alert saat keluar', value: GeofenceAlertTypeEdit.exit, group: selected, onChanged: onChanged),
      ],
    );
  }
}
 
class _RadioEdit extends StatelessWidget {
  final String label;
  final GeofenceAlertTypeEdit value;
  final GeofenceAlertTypeEdit group;
  final ValueChanged<GeofenceAlertTypeEdit> onChanged;
  const _RadioEdit({required this.label, required this.value, required this.group, required this.onChanged});
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<GeofenceAlertTypeEdit>(
            value: value,
            groupValue: group,
            onChanged: (v) => onChanged(v!),
            activeColor: AppColorTheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(label, style: AppTextTheme.bodyMedium),
        ],
      ),
    );
  }
}
