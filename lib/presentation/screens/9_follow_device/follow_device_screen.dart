import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/distance_util.dart';
import 'package:nusantara_gps/core/utils/time_extention.dart';
import 'package:nusantara_gps/core/utils/url_opener.dart';
import 'package:nusantara_gps/data/models/device.dart';
import 'package:nusantara_gps/data/models/position.dart';
import 'package:nusantara_gps/presentation/screens/9_follow_device/follow_device_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/custom_snack_bar.dart';
import 'package:nusantara_gps/presentation/widgets/default_padding.dart';
import 'package:nusantara_gps/presentation/widgets/map_type_bottom_sheet.dart';
import 'package:provider/provider.dart';

class FollowDeviceScreen extends StatelessWidget {
  final int deviceId;
  const FollowDeviceScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FollowDeviceViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: Text("Ikuti Kendaraan", style: AppTextTheme.titleMedium),
        centerTitle: true,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "direct_google_maps",
            onPressed: () {
              openUrl(
                'https://www.google.com/maps/dir/?api=1'
                '&origin=${viewModel.currentLatLng?.latitude},${viewModel.currentLatLng?.longitude}'
                '&destination=${viewModel.position?.latitude},${viewModel.position?.longitude}'
                '&travelmode=driving',
              );
            },
            foregroundColor: AppColorTheme.primary,
            backgroundColor: Colors.white,
            child: const Icon(Icons.directions_outlined),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "street_view",
            onPressed: () {
              openUrl(
                'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${viewModel.position?.latitude},${viewModel.position?.longitude ?? 0}&heading=0&pitch=0',
              );
            },
            foregroundColor: AppColorTheme.primary,
            backgroundColor: Colors.white,
            child: const Icon(Icons.streetview),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "map_type",
            onPressed: () {
              showMapTypeBottomSheet(
                context: context,
                currentMapType: viewModel.mapType,
                onMapTypeSelected: (mapType) {
                  viewModel.changeMapType(mapType);
                },
              );
            },
            foregroundColor: AppColorTheme.primary,
            backgroundColor: Colors.white,
            child: const Icon(Icons.layers_rounded),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "vehicle_location",
            backgroundColor: AppColorTheme.primary,
            foregroundColor: Colors.white,
            onPressed: () {
              viewModel.recenterVehicleLocation();
            },
            child: const Icon(Icons.directions_car_rounded),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "self_location",
            backgroundColor: AppColorTheme.primary,
            foregroundColor: Colors.white,
            onPressed: () {
              viewModel.recenterSelfLocation();
            },
            child: const Icon(Icons.my_location_rounded),
          ),
          const SizedBox(height: 16),
        ],
      ),
      body: SafeArea(
        child: Consumer<FollowDeviceViewModel>(
          builder: (context, viewModel, child) {
            final center =
                viewModel.currentLatLng ?? LatLng(-7.936738, 112.617612);
            return Stack(
              children: [
                GoogleMap(
                  trafficEnabled: true,
                  zoomControlsEnabled: false,
                  mapType: viewModel.mapType,
                  initialCameraPosition: CameraPosition(
                    target: center,
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {
                    viewModel.setMapController(controller);
                  },
                  polylines: viewModel.polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                  markers: viewModel.buildMarkers(viewModel.position),
                ),
                switch (viewModel.loadTrackingDataState) {
                  ResultState.loading => Center(
                    child: CupertinoActivityIndicator(),
                  ),
                  ResultState.error => CustomSnackbarWithStack(
                    message: viewModel.errorMessage ?? "Terjadi Kesalahan",
                    trailling: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                      ),
                      onPressed: () {
                        viewModel.startPolling(deviceId);
                      },
                      child: Text(
                        'retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  ResultState.success => Positioned(
                    top: 16,
                    right: 16,
                    left: 16,
                    child: _DeviceStatusWidget(
                      devicePosition: viewModel.position,
                      device: viewModel.device,
                      distance: viewModel.distance,
                      address: viewModel.selectedDeviceAddress,
                    ),
                  ),
                  _ => SizedBox.fromSize(),
                },
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeviceStatusWidget extends StatelessWidget {
  const _DeviceStatusWidget({
    required this.devicePosition,
    required this.device,
    required this.distance,
    required this.address,
  });

  final PositionModel? devicePosition;
  final Device? device;
  final double distance;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorTheme.gray50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorTheme.gray900.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColorTheme.primary,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device?.name ?? "loading...",
                        style: AppTextTheme.titleSmall.copyWith(
                          color: AppColorTheme.gray50,
                        ),
                      ),
                      Text(
                        "${device?.phone} - ${device?.model}",
                        style: AppTextTheme.bodySmall.copyWith(
                          color: AppColorTheme.gray50,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${devicePosition?.speed.toStringAsFixed(2)} km/h",
                  style: AppTextTheme.titleLarge.copyWith(
                    color: AppColorTheme.gray50,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          DefaultPadding(
            paddingHorizontal: 16,
            paddingBottom: 4,
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColorTheme.gray400),
                SizedBox(width: 8),
                Text(
                  "${devicePosition?.serverTimeUTC.timeAgo()}",
                  style: AppTextTheme.bodyMedium.copyWith(
                    color: AppColorTheme.gray600,
                  ),
                ),
                SizedBox(width: 16),
                Icon(
                  Icons.satellite_alt_outlined,
                  size: 14,
                  color: AppColorTheme.gray400,
                ),
                SizedBox(width: 8),
                Text(
                  "sat ${devicePosition?.sat}",
                  style: AppTextTheme.bodyMedium.copyWith(
                    color: AppColorTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
          DefaultPadding(
            paddingHorizontal: 16,
            paddingBottom: 4,
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColorTheme.gray400,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Long: ${devicePosition?.longitude.toStringAsFixed(4)}",
                      style: AppTextTheme.bodyMedium.copyWith(
                        color: AppColorTheme.gray600,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColorTheme.gray400,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Lat: ${devicePosition?.latitude.toStringAsFixed(4)}",
                      style: AppTextTheme.bodyMedium.copyWith(
                        color: AppColorTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          DefaultPadding(child: Divider(color: AppColorTheme.gray200)),
          DefaultPadding(
            paddingHorizontal: 16,
            paddingBottom: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 16,
                  color: AppColorTheme.gray400,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: AppTextTheme.bodyMedium.copyWith(
                      color: AppColorTheme.gray600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          DefaultPadding(child: Divider(color: AppColorTheme.gray200)),
          DefaultPadding(
            child: Row(
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 24,
                  color: AppColorTheme.gray400,
                ),
                Icon(
                  Icons.keyboard_double_arrow_right_outlined,
                  size: 24,
                  color: AppColorTheme.gray400,
                ),
                Icon(Icons.boy_rounded, size: 24, color: AppColorTheme.gray400),
                SizedBox(width: 8),
                Text(
                  distance.toReadableDistance(),
                  style: AppTextTheme.bodyMedium.copyWith(
                    color: AppColorTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
