import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/domain/entities/map_type.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/widgets/google_map_widget.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/maps_view_model.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/widgets/osm_map_widget.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/widgets/vehicle_list_bottom_sheet.dart';
import 'package:nusantara_gps/presentation/widgets/custom_snack_bar.dart';
import 'package:nusantara_gps/presentation/widgets/default_padding.dart';
import 'package:nusantara_gps/presentation/widgets/map_type_bottom_sheet.dart';
import 'package:provider/provider.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.select((MapsViewModel vm) => vm.mapLoading);
    final mapsViewModel = context.watch<MapsViewModel>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColorTheme.primary,
        title: Row(
          children: [
            Text(
              "Nusantara GPS",
              style: AppTextTheme.titleLarge.copyWith(color: Colors.white),
            ),
            Spacer(),
            IconButton(
              onPressed: () => context.push('/alert'),
              icon: Icon(
                Icons.notifications_outlined,
                color: AppColorTheme.gray50,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (mapsViewModel.mapSource == MapSource.google)
            FloatingActionButton(
              heroTag: "map_type",
              onPressed: () {
                showMapTypeBottomSheet(
                  context: context,
                  currentMapType: mapsViewModel.mapType,
                  onMapTypeSelected: (type) {
                    mapsViewModel.changeMapType(type);
                  },
                );
              },
              foregroundColor: AppColorTheme.primary,
              backgroundColor: Colors.white,
              child: const Icon(Icons.layers_rounded),
            ),
          const SizedBox(height: 16),

          Consumer<MapsViewModel>(
            builder: (context, vm, _) => FloatingActionButton(
              heroTag: "toggle_geofence",
              backgroundColor: vm.showGeofenceOverlay
                  ? AppColorTheme.primary
                  : Colors.white,
              foregroundColor: vm.showGeofenceOverlay
                  ? Colors.white
                  : AppColorTheme.primary,
              onPressed: () => vm.toggleGeofenceOverlay(),
              tooltip: vm.showGeofenceOverlay ? 'Sembunyikan Geofence' : 'Tampilkan Geofence',
              child: const Icon(Icons.pentagon_outlined),
            ),
          ),
          const SizedBox(height: 16),

          FloatingActionButton(
            heroTag: "current_location",
            backgroundColor: AppColorTheme.primary,
            foregroundColor: Colors.white,
            onPressed: () {
              // re-center location
              mapsViewModel.recenterSelfLocation();
            },
            child: const Icon(Icons.my_location_rounded),
          ),
          const SizedBox(height: 16),

          FloatingActionButton(
            heroTag: "list_device",
            backgroundColor: AppColorTheme.primary,
            foregroundColor: Colors.white,
            onPressed: () {
              showListVehicleSheet(context, mapsViewModel);
            },
            child: const Icon(Icons.directions_car_rounded),
          ),
          const SizedBox(height: 16),
          
          FloatingActionButton(
            heroTag: "map_source",
            backgroundColor: AppColorTheme.primary,
            foregroundColor: Colors.white,
            onPressed: () {
              showModalBottomSheet(
                backgroundColor: Colors.white,
                context: context,
                builder: (ctx) {
                  return ChangeNotifierProvider.value(
                    value: mapsViewModel,
                    child: _MapSourceSheet(),
                  );
                },
              );
            },
            child: const Icon(Icons.map_outlined),
          ),
          const SizedBox(height: 48),
        ],
      ),
      body: isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Consumer<MapsViewModel>(
              builder: (context, viewModel, child) {
                return Stack(
                  children: [
                    if (viewModel.mapSource == MapSource.google)
                      GoogleMapWidget(),
                    if (viewModel.mapSource == MapSource.osm) OsmMapWidget(),
                    Positioned(
                      top: 16,
                      right: 16,
                      left: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 12,
                        children:
                            VehicleStatus.values.map((status) {
                              return _VehicleItemStatistic(
                                status: status,
                                count: viewModel.statusCounts[status] ?? 0,
                                onTap: () => viewModel.setFilterStatus(status),
                                isSelected: viewModel.filterStatus == status,
                              );
                            }).toList()..add(
                              _VehicleItemStatistic(
                                status: null,
                                count: viewModel.devices.length,
                                onTap: () => viewModel.setFilterStatus(null),
                                isSelected: viewModel.filterStatus == null,
                              ),
                            ),
                      ),
                    ),
                    switch (viewModel.loadTrackingDataState) {
                      ResultState.loading => Center(
                        child: CircularProgressIndicator(
                          color: AppColorTheme.primary,
                        ),
                      ),
                      ResultState.error => CustomSnackbarWithStack(
                        message: viewModel.errorMessage ?? "Terjadi Kesalahan",
                        trailling: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                          ),
                          onPressed: () {
                            viewModel.loadInitial();
                          },
                          child: Text(
                            'retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      _ => SizedBox.shrink(),
                    },
                  ],
                );
              },
            ),
    );
  }
}

class _VehicleItemStatistic extends StatelessWidget {
  const _VehicleItemStatistic({
    this.status,
    required this.count,
    required this.onTap,
    this.isSelected = false,
  });

  final VehicleStatus? status;
  final int count;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColorTheme.green500 : AppColorTheme.gray50,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColorTheme.green400 : Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (status != null)
              Image.asset(status!.iconAsset, width: 32)
            else
              const Text('All  '),
            Text(
              "$count",
              style: AppTextTheme.labelLarge.copyWith(
                color: isSelected
                    ? AppColorTheme.gray50
                    : AppColorTheme.gray800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<MapsViewModel>();
    final mapSource = context.select((MapsViewModel vm) => vm.mapSource);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          DefaultPadding(
            child: Text(
              'Pilih Sumber Peta',
              style: AppTextTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RadioGroup<MapSource>(
            groupValue: mapSource,
            onChanged: (value) {
              if (value == null) return;
              viewModel.changeMapSource(value);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const ListTile(
                  title: Text('Open Street Map'),
                  leading: Radio<MapSource>(value: MapSource.osm),
                ),
                const ListTile(
                  title: Text('Google Map'),
                  leading: Radio<MapSource>(value: MapSource.google),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
