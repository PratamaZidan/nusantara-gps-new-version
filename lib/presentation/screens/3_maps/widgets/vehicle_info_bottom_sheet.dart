// import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/utils/time_extention.dart';
import 'package:nusantara_gps/core/utils/url_opener.dart';
import 'package:nusantara_gps/core/utils/distance_util.dart';
// import 'package:nusantara_gps/data/dto/location_iq_dto.dart';
import 'package:nusantara_gps/data/models/device.dart';
import 'package:nusantara_gps/data/models/position.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/maps_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/animation/slide_fade_in.dart';
import 'package:nusantara_gps/presentation/widgets/default_padding.dart';
import 'package:provider/provider.dart';

String _batteryDisplay(PositionModel? p) {
  if (p == null) return '-';

  if (p.batteryPercent != null) {
    final percent = p.batteryPercent!;
    if (p.voltageLevel != null) {
      return '$percent%';
    }
    return '$percent%';
  }

  return '-';
}

String _buildPositionValue(PositionModel? p, String address) {
  final lat = p?.latitude;
  final lng = p?.longitude;

  final coordinateText =
      (lat != null && lng != null) ? '$lat, $lng' : '-';

  final trimmedAddress = address.trim();
  if (trimmedAddress.isEmpty) {
    return '$coordinateText';
  }

  return '($coordinateText)\n$trimmedAddress';
}

void showVehicleSheet(
  BuildContext context,
  Device v,
  // PositionModel? p,
  // String address,
) {
  final mapsVm = context.read<MapsViewModel>();
  showModalBottomSheet(
    backgroundColor: Colors.white,
    isScrollControlled: true,
    context: context,
    builder: (ctx) {
      return ChangeNotifierProvider.value(
        value: mapsVm,
        child: Consumer<MapsViewModel>(
          builder: (context, vm, _) {
            final p = vm.getPositionByDeviceId(v.id);
            final address = vm.getAddressByDeviceId(v.id) ?? '-';
            final height = MediaQuery.of(ctx).size.height;
      return SizedBox(
        height: height * 0.5,
        child: Column(
          children: [
            DefaultPadding(
              paddingHorizontal: 16,
              child: Row(
                children: [
                  Spacer(),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.close, color: AppColorTheme.gray400),
                  ),
                ],
              ),
            ),
            SlideFadeIn(
              child: ListTile(
                title: Text(v.name, style: AppTextTheme.labelLarge),
                subtitle: Text(
                  "${v.model}\n${v.uniqueId}",
                  style: AppTextTheme.bodySmall.copyWith(
                    color: AppColorTheme.gray500,
                  ),
                ),
                leading: Image.asset(
                  p?.status.iconAsset ?? v.status.iconAsset,
                  width: 56,
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColorTheme.primary),
                  ),
                  child: Text(
                    'Detail',
                    style: AppTextTheme.labelLarge.copyWith(
                      color: AppColorTheme.primary,
                    ),
                  ),
                ),
                onTap: () => context.push('/vehicle-detail/${v.id}'),
              ),
            ),
            DefaultPadding(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SlideFadeIn(
                    delay: 0.2,
                    child: _MenuItemWidget(
                      label: 'Ikuti',
                      imageAsset: 'assets/icons/ic_follow.png',
                      onTap: () {
                        context.push('/follow-device/${v.id}');
                      },
                    ),
                  ),
                  SlideFadeIn(
                    delay: 0.3,
                    child: _MenuItemWidget(
                      label: 'Street\nView',
                      imageAsset: 'assets/icons/ic_street_view.png',
                      onTap: () {
                        openUrl(
                          'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${p?.latitude ?? 0},${p?.longitude ?? 0}&heading=0&pitch=0',
                        );
                      },
                    ),
                  ),
                  SlideFadeIn(
                    delay: 0.4,
                    child: _MenuItemWidget(
                      label: 'Report\nPerjalanan',
                      imageAsset: 'assets/icons/ic_route.png',
                      onTap: () {
                        context.push('/route-history/${v.id}');
                      },
                    ),
                  ),
                  SlideFadeIn(
                    delay: 0.5,
                    child: _MenuItemWidget(
                      label: 'Laporan\nHarian',
                      imageAsset: 'assets/icons/ic_report.png',
                      onTap: () {
                        context.push('/trip-report/${v.id}');
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 6,
                radius: Radius.circular(8),
                child: ListView(
                  children: [
                    _VehicleDataRow(
                      label: "Kecepatan",
                      value: '${p?.speed.toStringAsFixed(1)} km/h',
                      icon: Icons.air_rounded,
                    ),
                    _VehicleDataRow(
                      label: "Arah",
                      value: '${p?.course}°',
                      icon: CupertinoIcons.location,
                    ),
                    _VehicleDataRow(
                      label: "Update",
                      value:
                          p?.serverTimeUTC.timeAgo(
                            reference: DateTime.now().toUtc(),
                            numeric: false,
                          ) ??
                          'null',
                      icon: Icons.access_time_outlined,
                    ),
                    _VehicleDataRow(
                      label: "Posisi",
                      value: _buildPositionValue(p, address),
                    ),
                    // _VehicleDataRow(label: "Alamat", value: address),
                    _VehicleDataRow(
                      label: "Satellite",
                      value: '${p?.sat}',
                      icon: Icons.satellite_alt_outlined,
                    ),
                    _VehicleDataRow(
                      label: "Baterai",
                      value: _batteryDisplay(p),
                      icon: Icons.battery_charging_full_rounded,
                    ),
                    _VehicleDataRow(
                      label: "Total Jarak",
                      value: p == null ? '-' : p.totalDistance.toKmOdometer(),
                      icon: Icons.directions_walk_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      },
        ),
      );
    },
  );
}

class _MenuItemWidget extends StatelessWidget {
  final String label;
  final String imageAsset;
  final VoidCallback? onTap;
  const _MenuItemWidget({
    required this.label,
    required this.imageAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColorTheme.green50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                imageAsset,
                height: 24,
                width: 24,
                color: AppColorTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _VehicleDataRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  const _VehicleDataRow({
    required this.label,
    required this.value,
    this.icon = Icons.location_on_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultPadding(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColorTheme.gray100),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 8),
            Text(label, style: AppTextTheme.bodyMedium),
            Spacer(),
            SizedBox(
              width: 200,
              child: Text(
                value,
                softWrap: true,
                maxLines: null,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.end,
                style: AppTextTheme.bodyMedium.copyWith(
                  color: AppColorTheme.gray500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
