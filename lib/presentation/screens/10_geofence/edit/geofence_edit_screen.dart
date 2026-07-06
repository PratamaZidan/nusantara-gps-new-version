import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/domain/entities/geofence_draw_mode.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/edit/geofence_edit_view_model.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/widgets/alert_type_selector.dart';
import 'package:nusantara_gps/presentation/widgets/app_button.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/widgets/geofence_draw_toolbar.dart';
import 'package:nusantara_gps/presentation/widgets/rounded_text_field.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/widgets/vehicle_multi_select.dart';
import 'package:provider/provider.dart';

class GeofenceEditScreen extends StatefulWidget {
  final int geofenceId;
  const GeofenceEditScreen({super.key, required this.geofenceId});

  @override
  State<GeofenceEditScreen> createState() => _GeofenceEditScreenState();
}

class _GeofenceEditScreenState extends State<GeofenceEditScreen> {
  static const LatLng _defaultCenter = LatLng(-7.936738, 112.617612);
  GoogleMapController? _mapController;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<GeofenceEditViewModel>();
      await vm.loadVehicles();
      await vm.loadGeofence();
      // Setelah data load, pan kamera ke lokasi geofence
      if (_mapReady && mounted) {
        final center = vm.drawManager.circleCenter ??
            vm.drawManager.rectStart ??
            (vm.drawManager.polygonPoints.isNotEmpty
                ? vm.drawManager.polygonPoints.first
                : null);
        if (center != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(center, 15),
          );
        }
      }
    });
  }

  Future<void> _onSave() async {
    final vm = context.read<GeofenceEditViewModel>();
    if (vm.nameController.text.trim().isEmpty) {
      _snack('Nama pagar tidak boleh kosong');
      return;
    }
    if (!vm.drawManager.isAreaReady) {
      _snack('Area geofence belum selesai digambar');
      return;
    }
    await vm.updateGeofence();
    if (!mounted) return;
    if (vm.updateGeofenceState == ResultState.success) {
      _snack('Geofence berhasil diperbarui', isError: false);
      Navigator.of(context).pop(true);
    } else {
      _snack(vm.errorMessage ?? 'Gagal memperbarui geofence');
    }
  }

  void _snack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColorTheme.red500 : AppColorTheme.green600,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeofenceEditViewModel>();

    if (vm.loadState == ResultState.loading) {
      return const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (vm.loadState == ResultState.error) {
      return Scaffold(
        appBar: AppBar(title: Text('Edit Pagar Virtual', style: AppTextTheme.titleMedium)),
        body: Center(child: Text(vm.errorMessage ?? 'Gagal memuat data')),
      );
    }

    return ListenableBuilder(
      listenable: vm.drawManager,
      builder: (context, _) {
        final dm = vm.drawManager;

        return Scaffold(
          appBar: AppBar(
            title: Text('Edit Pagar Virtual', style: AppTextTheme.titleMedium),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // PETA 
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (c) {
                        _mapController = c;
                        _mapReady = true;
                        // Pan ke area geofence setelah map ready
                        final center = dm.circleCenter ??
                            dm.rectStart ??
                            (dm.polygonPoints.isNotEmpty
                                ? dm.polygonPoints.first
                                : null);
                        if (center != null) {
                          Future.delayed(const Duration(milliseconds: 400), () {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(center, 15),
                            );
                          });
                        }
                      },
                      initialCameraPosition: CameraPosition(
                        target: dm.circleCenter ??
                            dm.rectStart ??
                            (dm.polygonPoints.isNotEmpty
                                ? dm.polygonPoints.first
                                : _defaultCenter),
                        zoom: 14,
                      ),
                      scrollGesturesEnabled: dm.drawMode == GeofenceDrawMode.pan,
                      zoomGesturesEnabled: true,
                      onTap: dm.drawMode != GeofenceDrawMode.pan ? dm.onMapTap : null,
                      circles: dm.previewCircles,
                      polygons: {...dm.previewRectangle, ...dm.previewPolygon},
                      markers: dm.polygonMarkers,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                    ),

                    // Toolbar
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GeofenceDrawToolbar(
                        selected: dm.drawMode,
                        onModeChanged: dm.setDrawMode,
                      ),
                    ),

                    // Hint
                    Positioned(
                      top: 12,
                      left: 180,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6)],
                        ),
                        child: Text(dm.hintText, style: AppTextTheme.bodySmall, maxLines: 2),
                      ),
                    ),

                    // Polygon actions
                    if (dm.drawMode == GeofenceDrawMode.polygon)
                      Positioned(
                        bottom: 12, left: 12, right: 12,
                        child: Row(
                          children: [
                            if (dm.polygonPoints.isNotEmpty && !dm.isPolygonClosed)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: dm.removeLastPolygonPoint,
                                  icon: const Icon(Icons.undo_rounded, size: 16),
                                  label: const Text('Undo'),
                                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                                ),
                              ),
                            if (dm.polygonPoints.length >= 3 && !dm.isPolygonClosed) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: dm.closePolygon,
                                  icon: const Icon(Icons.check_rounded, size: 16),
                                  label: const Text('Tutup Polygon'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColorTheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            if (dm.isPolygonClosed)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => dm.setDrawMode(GeofenceDrawMode.polygon),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Gambar Ulang'),
                                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Rectangle reset
                    if (dm.drawMode == GeofenceDrawMode.rectangle &&
                        dm.rectStart != null && dm.rectEnd != null)
                      Positioned(
                        bottom: 12, left: 12, right: 12,
                        child: OutlinedButton.icon(
                          onPressed: dm.resetRectangle,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Gambar Ulang'),
                          style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              // FORM 
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nama Pagar', style: AppTextTheme.labelMedium),
                      const SizedBox(height: 6),
                      RoundedTextField(
                        controller: vm.nameController,
                        hint: 'Nama area geofence',
                        icon: Icons.edit_location_rounded,
                      ),

                      if (dm.drawMode == GeofenceDrawMode.circle) ...[
                        const SizedBox(height: 14),
                        Text('Radius (meter)', style: AppTextTheme.labelMedium),
                        const SizedBox(height: 6),
                        RoundedTextField(
                          controller: vm.radiusController,
                          hint: '100',
                          icon: Icons.straighten_rounded,
                          keyboardType: TextInputType.number,
                          onChanged: vm.onRadiusChanged,
                        ),
                      ],

                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 18),

                      Text('Jenis pagar virtual', style: AppTextTheme.labelMedium),
                      const SizedBox(height: 8),
                      // Reuse AlertTypeSelector — cast ke GeofenceAlertType
                      AlertTypeSelectorEdit(
                        selected: vm.alertType,
                        onChanged: vm.setAlertType,
                      ),

                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 18),

                      Text('Set ke armada', style: AppTextTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih kendaraan yang akan dipantau',
                        style: AppTextTheme.bodySmall?.copyWith(color: AppColorTheme.gray400),
                      ),
                      const SizedBox(height: 10),

                      switch (vm.loadVehicleState) {
                        ResultState.loading => const Center(
                            child: Padding(padding: EdgeInsets.all(16), child: CupertinoActivityIndicator())),
                        ResultState.success => VehicleMultiSelect(
                            vehicles: vm.vehicles,
                            selectedIds: vm.selectedIds,
                            onToggle: vm.toggleVehicle,
                          ),
                        _ => const SizedBox.shrink(),
                      },

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: vm.updateGeofenceState == ResultState.loading
                            ? const Center(child: CupertinoActivityIndicator())
                            : AppButton(
                                label: 'Simpan Perubahan',
                                onPressed: dm.isAreaReady ? _onSave : null,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}