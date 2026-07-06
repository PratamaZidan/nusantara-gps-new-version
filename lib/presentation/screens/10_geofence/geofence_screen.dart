import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/geofence_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/custom_dialog_confirmation.dart';
import 'package:nusantara_gps/presentation/widgets/custom_snack_bar.dart';
import 'package:nusantara_gps/presentation/widgets/map_type_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/widgets/geofence_card.dart';

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<GeofenceViewModel>();
        vm.loadGeofence();
        vm.loadDevices();
      });
    }
  }

  Future<void> _navigateToCreate() async {
    final result = await context.push('/geofence/create');
    // Jika kembali dengan result true (berhasil disimpan), reload list
    if (result == true && mounted) {
      context.read<GeofenceViewModel>().loadGeofence();
    }
  }

  Future<void> _navigateToEdit(int geofenceId) async {
    final result = await context.push('/geofence-edit/$geofenceId');
      if (result == true && mounted) {
        context.read<GeofenceViewModel>().loadGeofence();
      }
    }

    Future<void> _confirmDelete(int geofenceId, String name) async {
    showConfirmDialog(
      context: context,
      title: 'Hapus Geofence',
      message:
          'Yakin ingin menghapus geofence "$name"? tindakan ini tidak bisa dibatalkan.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      color: Colors.red,
      onConfirm: () async {
        final vm = context.read<GeofenceViewModel>();
        await vm.deleteGeofence(geofenceId);

        if (!mounted) return;

        if (vm.deleteGeofenceState == ResultState.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geofence berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(vm.errorMessage ?? 'Gagal menghapus geofence'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeofenceViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColorTheme.defautGradient,
          ),
        ),
        title: Text("Pagar Virtual", style: AppTextTheme.titleMedium.copyWith(
          color: Colors.white, fontWeight: FontWeight.bold
        )),
        centerTitle: true,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // FAB Toggle Device Markers
          FloatingActionButton(
            heroTag: "toggle_devices",
            onPressed: vm.toggleDeviceMarkers,
            foregroundColor: vm.showDeviceMarkers
                ? Colors.white
                : AppColorTheme.primary,
            backgroundColor: vm.showDeviceMarkers
                ? AppColorTheme.primary
                : Colors.white,
            child: const Icon(Icons.directions_car_rounded),
          ),
          const SizedBox(height: 12),
          // FAB Ganti Tipe Peta
          FloatingActionButton(
            heroTag: "map_type",
            onPressed: () {
              showMapTypeBottomSheet(
                context: context,
                currentMapType: vm.mapType,
                onMapTypeSelected: vm.changeMapType,
              );
            },
            foregroundColor: AppColorTheme.primary,
            backgroundColor: Colors.white,
            child: const Icon(Icons.layers_rounded),
          ),
          const SizedBox(height: 12),
          // FAB Tambah Geofence
          FloatingActionButton(
            heroTag: "add_geofence",
            onPressed: _navigateToCreate,
            foregroundColor: Colors.white,
            backgroundColor: AppColorTheme.primary,
            child: const Icon(Icons.add_rounded),
          ),
          const SizedBox(height: 100),
        ],
      ),
      body: SafeArea(
        child: Consumer<GeofenceViewModel>(
          builder: (context, viewModel, child) {
            return Stack(
              children: [
                GoogleMap(
                  onMapCreated: viewModel.setMapController,
                  initialCameraPosition: CameraPosition(
                    target: viewModel.selectedGeofence?.polygon.first ??
                        const LatLng(-7.936738, 112.617612),
                    zoom: 12,
                  ),
                  mapType: viewModel.mapType,
                  polygons: viewModel.allPolygons,
                  markers: viewModel.deviceMarkers,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                ),

                switch (viewModel.loadGeofenceState) {
                  ResultState.loading => const Center(
                      child: CupertinoActivityIndicator(),
                    ),

                  ResultState.error => CustomSnackbarWithStack(
                      message: viewModel.errorMessage ?? "Terjadi Kesalahan",
                      trailling: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                        ),
                        onPressed: () {
                          viewModel.loadGeofence();
                        },
                        child: const Text(
                          'retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                  ResultState.success => Positioned(
                      bottom: 24,
                      left: 16,
                      right: 16,
                      child: viewModel.geofenceData.length == 1
                          ? GeofenceCard(
                              item: viewModel.geofenceData.first,
                              isSelected: true,
                              onTap: () {
                                viewModel.setSelectedGeoFence(
                                  viewModel.geofenceData.first,
                                );
                              },
                              onEdit: () => _navigateToEdit(
                                viewModel.geofenceData.first.id),
                              onDelete: () => _confirmDelete(
                                viewModel.geofenceData.first.id,
                                viewModel.geofenceData.first.name),
                          )
                          : CarouselSlider(
                            options: CarouselOptions(
                              viewportFraction: 0.82,
                              enlargeCenterPage: true,
                              aspectRatio: 4.2 / 1,
                              initialPage: 0,
                              onPageChanged: (index, reason) {
                                viewModel.setSelectedGeoFence(
                                  viewModel.geofenceData[index],
                                );
                              },
                            ),
                            items: viewModel.geofenceData.map((item) {
                              final isSelected =
                                  viewModel.selectedGeofence?.id == item.id;

                              return GeofenceCard(
                                item: item,
                                isSelected: isSelected,
                                onTap: () {
                                  viewModel.setSelectedGeoFence(item);
                                },
                                onEdit: () => _navigateToEdit(item.id),
                                onDelete: () =>
                                    _confirmDelete(item.id, item.name),
                              );
                            }).toList(),
                          ),
                    ),

                  ResultState.noData => Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColorTheme.primary.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_off_rounded,
                              size: 36,
                              color: AppColorTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Geofence',
                            style: AppTextTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Data pagar virtual belum tersedia untuk akun ini atau belum berhasil dimuat dari server.',
                            style: AppTextTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                viewModel.loadGeofence();
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Muat Ulang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColorTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _ => const SizedBox.shrink(),
                },
              ],
            );
          },
        ),
      ),
    );
  }
}