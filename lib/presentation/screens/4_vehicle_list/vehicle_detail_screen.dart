import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/di/dependency_injection.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/time_extention.dart';
import 'package:nusantara_gps/core/utils/url_opener.dart';
import 'package:nusantara_gps/data/models/detail_vehicle.dart';
import 'package:nusantara_gps/presentation/screens/4_vehicle_list/vehicle_detail_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/animation/simple_fade_in.dart';
import 'package:nusantara_gps/presentation/widgets/animation/slide_fade_in.dart';
import 'package:nusantara_gps/presentation/widgets/custom_dialog_confirmation.dart';
import 'package:nusantara_gps/presentation/widgets/default_error_widget.dart';
import 'package:nusantara_gps/presentation/widgets/default_padding.dart';
import 'package:nusantara_gps/presentation/widgets/vehicle_status_widget.dart';
import 'package:provider/provider.dart';
import 'package:nusantara_gps/core/utils/distance_util.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => locator<VehicleDetailViewModel>()..load(vehicleId),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          title: Text("Detail Perangkat", style: AppTextTheme.titleMedium),
        ),
        body: SafeArea(
          child: Consumer<VehicleDetailViewModel>(
            builder: (context, vm, _) {
              switch (vm.loadVehicleDetail) {
                case ResultState.loading:
                  return const Scaffold(
                    body: Center(child: CupertinoActivityIndicator()),
                  );
                case ResultState.success:
                  final v = vm.vehicle!;
                  return DetailVehicleContent(v: v, vm: vm);
                case ResultState.error:
                  return DefaultErrorWidget(
                    errorMessage: vm.errorMessage,
                    onRetry: () {
                      vm.load(vehicleId);
                    },
                  );
                case ResultState.noData:
                  return DefaultErrorWidget(errorMessage: "Tidak ada data");
                default:
                  return SizedBox.shrink();
              }
            },
          ),
        ),
      ),
    );
  }
}

class DetailVehicleContent extends StatelessWidget {
  const DetailVehicleContent({super.key, required this.v, required this.vm});

  final DetailVehicle v;
  final VehicleDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SlideFadeIn(
          child: ListTile(
            title: Text(
              "${v.vehicleBrand}",
              style: AppTextTheme.labelLarge,
            ),
            subtitle: Text(
              "${v.emei}",
              style: AppTextTheme.bodyMedium.copyWith(
                color: AppColorTheme.gray500,
              ),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                VehicleStatusWidget(
                  status: vm.position?.status ?? VehicleStatus.down,
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ),
        SimpleFadeIn(
          child: Divider(thickness: 6, height: 24, color: AppColorTheme.gray50),
        ),
        SlideFadeIn(
          delay: 0.2,
          child: DefaultPadding(
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColorTheme.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: switch (vm.loadPosition) {
                ResultState.loading => Center(
                  child: CupertinoActivityIndicator(),
                ),
                ResultState.success => GoogleMap(
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      vm.position?.latitude ?? 0,
                      vm.position?.longitude ?? 0,
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId("marker"),
                      position: LatLng(
                        vm.position?.latitude ?? 0,
                        vm.position?.longitude ?? 0,
                      ),
                      icon: BitmapDescriptor.defaultMarker,
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                ),
                ResultState.error => DefaultErrorWidget(),
                _ => SizedBox.shrink(),
              },
            ),
          ),
        ),
        SizedBox(height: 16),
        SlideFadeIn(
          delay: 0.4,
          child: DefaultPadding(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MenuItemWidget(
                  label: 'Ikuti',
                  imageAsset: 'assets/icons/ic_follow.png',
                  onTap: () {
                    context.push('/follow-device/${v.vehicleId}');
                  },
                ),

                _MenuItemWidget(
                  label: 'Street\nView',
                  imageAsset: 'assets/icons/ic_street_view.png',
                  onTap: () {
                    openUrl(
                      'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${v.lat},${v.lng}&heading=0&pitch=0',
                    );
                  },
                ),

                _MenuItemWidget(
                  label: 'Report\nPerjalanan',
                  imageAsset: 'assets/icons/ic_route.png',
                  onTap: () {
                    context.push('/route-history/${v.vehicleId}');
                  },
                ),

                _MenuItemWidget(
                  label: 'Laporan\nHarian',
                  imageAsset: 'assets/icons/ic_report.png',
                  onTap: () {
                    context.push('/trip-report/${v.vehicleId}');
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        SimpleFadeIn(
          child: Divider(thickness: 6, height: 24, color: AppColorTheme.gray50),
        ),
        SlideFadeIn(
          delay: 0.6,
          child: DefaultPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  "Data Kendaraan",
                  style: AppTextTheme.bodySmall.copyWith(
                    color: AppColorTheme.gray400,
                  ),
                ),

                _VehicleDataItemWidget(
                  label: "Id Kendaraan",
                  value: "${v.vehicleId}",
                ),

                _VehicleDataItemWidget(
                  label: "Brand Kendaraan",
                  value: "${v.vehicleBrand}",
                ),

                _VehicleDataItemWidget(
                  label: "Nomor Polisi",
                  value: "${v.platNumber}",
                ),
              ],
            ),
          ),
        ),
        SimpleFadeIn(
          child: Divider(thickness: 6, height: 24, color: AppColorTheme.gray50),
        ),
        SlideFadeIn(
          delay: 1,
          child: DefaultPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  "Data Perangkat",
                  style: AppTextTheme.bodySmall.copyWith(
                    color: AppColorTheme.gray400,
                  ),
                ),
                _VehicleDataItemWidget(label: "Model", value: v.model),
                _VehicleDataItemWidget(label: "Imei", value: v.emei),
                _VehicleDataItemWidget(label: "GSM", value: v.gsm),
                _VehicleDataItemWidget(
                  label: "Total Jarak Tempuh",
                  value: v.totalDistance.toKmOdometer(),
                ),
                _VehicleDataItemWidget(label: "Status", value: v.status.name),
                _VehicleDataItemWidget(
                  label: "Terakhir Diperbarui",
                  value: vm.position != null
                      ? vm.position!.serverTimeUTC.timeAgo(
                        reference: DateTime.now().toUtc(),
                        numeric: false,
                      )
                      : v.lastUpdate.timeAgo(),
                ),
              ],
            ),
          ),
        ),

        SimpleFadeIn(
          child: Divider(thickness: 6, height: 24, color: AppColorTheme.gray50),
        ),
        SlideFadeIn(
          delay: 1.2,
          child: _MenuListTileWidget(
            title: 'Fuel-Cut',
            subtitle: (vm.fuelCutSwitch) ? 'active' : 'non-active',
            trailing: Switch(
              value: vm.fuelCutSwitch,
              activeTrackColor: AppColorTheme.green400,
              trackOutlineWidth: WidgetStatePropertyAll<double>(1),
              trackOutlineColor: WidgetStatePropertyAll<Color>(
                AppColorTheme.gray300,
              ),
              onChanged: (v) {
                if (vm.fuelCutSwitch) {
                  vm.toggleFuelCutSwitch();
                } else {
                  showConfirmDialog(
                    context: context,
                    title: "Aktifkan Fuel-cut",
                    message: "Apakah anda yakin ingin mengaktifkan Fuel Cut?",
                    onConfirm: () {
                      context.pop();
                      vm.toggleFuelCutSwitch();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur belum tersedia')),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
        SlideFadeIn(
          delay: 1.4,
          child: _MenuListTileWidget(
            title: 'Sadap Perangkat',
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur belum tersedia')),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VehicleDataItemWidget extends StatelessWidget {
  final String label;
  final String value;

  const _VehicleDataItemWidget({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: AppTextTheme.bodyMedium.copyWith(
              color: AppColorTheme.gray500,
            ),
          ),
        ),
        SizedBox(width: 4),
        Text(
          value,
          softWrap: true,
          maxLines: null,
          overflow: TextOverflow.visible,
          textAlign: TextAlign.end,
          style: AppTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _MenuListTileWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  const _MenuListTileWidget({
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColorTheme.gray100),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          title: Text(title),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: AppTextTheme.bodyMedium.copyWith(
                    color: AppColorTheme.gray500,
                  ),
                )
              : null,
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
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
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: AppColorTheme.green50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                imageAsset,
                height: 28,
                width: 28,
                color: AppColorTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
