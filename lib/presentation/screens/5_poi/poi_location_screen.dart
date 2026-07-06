import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/data/models/poi_model.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/poi_location_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/animation/slide_fade_in.dart';
import 'package:nusantara_gps/presentation/widgets/app_button.dart';
import 'package:nusantara_gps/presentation/widgets/custom_dialog_confirmation.dart';
import 'package:nusantara_gps/presentation/widgets/custom_snack_bar.dart';
import 'package:nusantara_gps/presentation/widgets/map_type_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class FavoriteLocationScreen extends StatelessWidget {
  const FavoriteLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoriteLocationViewModel>();

    final LatLng center = vm.items.isNotEmpty
        ? LatLng(vm.items.first.lat, vm.items.first.lng)
        : const LatLng(-7.936738, 112.617612);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColorTheme.defautGradient,
          ),
        ),
        title: Text('Lokasi Minat', style: AppTextTheme.titleMedium.copyWith(
          color: Colors.white, fontWeight: FontWeight.bold
        )),
        centerTitle: true,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tombol Refresh
          FloatingActionButton(
            heroTag: 'refresh_poi',
            onPressed: vm.refresh,
            backgroundColor: AppColorTheme.primary,
            foregroundColor: Colors.white,
            child: (vm.loadFavoriteLocationState == ResultState.loading)
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Icon(Icons.refresh),
          ),
          const SizedBox(height: 12),

          // Tombol Ganti Layer Peta
          FloatingActionButton(
            heroTag: 'map_type_poi',
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

          // Tombol Tambah POI
          FloatingActionButton(
            heroTag: 'add_poi',
            onPressed: () {
              if (vm.selectedLatLng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tap titik di peta terlebih dahulu untuk menentukan lokasi'),
                    duration: Duration(seconds: 3),
                  ),
                );
              } else {
                context.pushNamed(
                  'poi-create',
                  queryParameters: {
                    'lat': vm.selectedLatLng!.latitude.toString(),
                    'lng': vm.selectedLatLng!.longitude.toString(),
                  },
                );
              }
            },
            backgroundColor: AppColorTheme.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_location_alt_rounded),
          ),
          const SizedBox(height: 48),
        ],
      ),
      body: SafeArea(
        child: Consumer<FavoriteLocationViewModel>(
          builder: (context, viewModel, _) {
            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: center, zoom: 12),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: true,
                  zoomControlsEnabled: false,
                  mapType: viewModel.mapType,
                  markers: _buildMarkers(context, viewModel),
                  onTap: (latLng) {
                    viewModel.setSelectedLatLng(latLng);
                  },
                ),

                // Hint tap lokasi
                if (viewModel.selectedLatLng == null)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 80,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app, size: 16, color: AppColorTheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tap peta untuk memilih lokasi baru',
                              style: AppTextTheme.bodySmall.copyWith(color: AppColorTheme.neutral),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Status loading / error
                switch (viewModel.loadFavoriteLocationState) {
                  ResultState.loading => const Center(child: CircularProgressIndicator()),
                  ResultState.error   => CustomSnackbarWithStack(
                      message: viewModel.errorMessage ?? 'Terjadi Kesalahan',
                      trailling: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
                        onPressed: viewModel.loadFavoriteLocation,
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
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

  Set<Marker> _buildMarkers(BuildContext context, FavoriteLocationViewModel vm) {
    final markers = vm.items.map((poi) {
      // Pakai icon asli dari cache kalau sudah siap, fallback ke default merah
      final icon = vm.iconDescriptors[poi.icon] ?? BitmapDescriptor.defaultMarker;
      return Marker(
        markerId: MarkerId('poi_${poi.id}'),
        position: LatLng(poi.lat, poi.lng),
        icon: icon,
        infoWindow: InfoWindow(
          title: poi.nama,
          snippet: poi.keterangan.isNotEmpty ? poi.keterangan : 'Lokasi Minat',
          onTap: () => _showPoiDetail(context, poi, vm),
        ),
      );
    }).toSet();

    // Marker titik yang dipilih user (biru)
    if (vm.selectedLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: vm.selectedLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    return markers;
  }
}

// Buka Google Maps navigasi ke POI
Future<void> _openGoogleMapsRoute(double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// Lihat foto POI fullscreen
void _showPhotoFullscreen(BuildContext context, String? localPath, String photoUrl) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: (localPath != null)
                    ? Image.file(
                        File(localPath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image, color: Colors.white, size: 80,
                        ),
                      )
                    : Image.network(
                        photoUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator(color: Colors.white)),
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image, color: Colors.white, size: 80,
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 48, right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Bottom Sheet Detail POI
void _showPoiDetail(BuildContext context, PoiModel poi, FavoriteLocationViewModel vm) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PoiDetailSheet(
      poi: poi, 
      vm: vm,
      parentContext: context,
      ),
  );
}

class _PoiDetailSheet extends StatelessWidget {
  final PoiModel poi;
  final FavoriteLocationViewModel vm;
  final BuildContext parentContext;

  const _PoiDetailSheet({
    required this.poi, 
    required this.vm,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto / icon POI — tap untuk lihat fullscreen
                GestureDetector(
                  onTap: () => _showPhotoFullscreen(
                    context,
                    poi.localImagePath,
                    poi.fullPhotoUrl,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: poi.localImagePath != null
                            ? Image.file(
                                File(poi.localImagePath!),
                                width: 56, height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColorTheme.green100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.place, color: AppColorTheme.primary, size: 32),
                                ),
                              )
                            : Image.network(
                                poi.fullPhotoUrl,
                                width: 56, height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColorTheme.green100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.place, color: AppColorTheme.primary, size: 32),
                                ),
                              ),
                      ),
                      // Badge zoom
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TITIK LOKASI',
                        style: AppTextTheme.bodySmall.copyWith(color: AppColorTheme.green700),
                      ),
                      const SizedBox(height: 2),
                      Text(poi.nama, style: AppTextTheme.titleLarge,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            if (poi.keterangan.isNotEmpty) ...[
              const SizedBox(height: 10),
              SlideFadeIn(
                delay: 0.1,
                child: Text(poi.keterangan,
                    style: AppTextTheme.bodyMedium,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],

            // Koordinat
            const SizedBox(height: 12),
            SlideFadeIn(
              delay: 0.2,
              child: Row(
                children: [
                  Expanded(child: _CoordTile(label: 'LATITUDE',  value: poi.lat.toStringAsFixed(6))),
                  Expanded(child: _CoordTile(label: 'LONGITUDE', value: poi.lng.toStringAsFixed(6))),
                ],
              ),
            ),

            // Tombol Rute, Edit & Hapus
            const SizedBox(height: 20),
            SlideFadeIn(
              delay: 0.3,
              child: Row(
                children: [
                  // Tombol Edit
                  Expanded(
                    child: AppButton(
                      label: 'Rute',
                      icon: const Icon(Icons.directions_rounded),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openGoogleMapsRoute(poi.lat, poi.lng);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Edit',
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () {
                        // Simpan router SEBELUM pop agar context bottom sheet
                        // tidak invalid saat pushNamed dipanggil
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        router.pushNamed(
                          'poi-edit',
                          pathParameters: {'id': poi.id.toString()},
                          extra: poi,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Hapus
                  Expanded(
                    child: AppButton(
                      label: 'Hapus',
                      isSecondary: true,
                      icon: const Icon(Icons.delete_rounded),
                      gradient: LinearGradient(
                        colors: [
                          AppColorTheme.red,
                          AppColorTheme.red.withOpacity(0.9),
                        ],
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Future.delayed(const Duration(milliseconds: 300));
                        if (!parentContext.mounted) return;
                        showConfirmDialog(
                          context: parentContext,
                          title: 'Hapus POI?',
                          message: 'POI "${poi.nama}" akan dihapus permanen.',
                          confirmText: 'HAPUS',
                          color: AppColorTheme.red,
                          onConfirm: () {
                            vm.deletePoi(poi.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordTile extends StatelessWidget {
  final String label;
  final String value;
  const _CoordTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextTheme.bodySmall.copyWith(color: AppColorTheme.green700)),
        const SizedBox(height: 2),
        Text(value, style: AppTextTheme.titleMedium),
      ],
    );
  }
}