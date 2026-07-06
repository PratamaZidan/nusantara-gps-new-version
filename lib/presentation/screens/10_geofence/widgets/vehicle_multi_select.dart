import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/data/models/vehicle_model.dart';

class VehicleMultiSelect extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const VehicleMultiSelect({
    super.key,
    required this.vehicles,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        border: Border.all(color: AppColorTheme.gray200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          itemCount: vehicles.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColorTheme.gray100,
          ),
          itemBuilder: (context, i) {
            final v = vehicles[i];
            final isSelected = selectedIds.contains(v.id);

            return InkWell(
              onTap: () => onToggle(v.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColorTheme.green100
                            : AppColorTheme.gray100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        size: 18,
                        color: isSelected
                            ? AppColorTheme.primary
                            : AppColorTheme.gray400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.model,
                            style: AppTextTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            v.plateNumber,
                            style: AppTextTheme.bodySmall
                                ?.copyWith(color: AppColorTheme.gray400),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggle(v.id),
                      activeColor: AppColorTheme.primary,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}