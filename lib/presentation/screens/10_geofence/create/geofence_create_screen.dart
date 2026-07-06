import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/domain/entities/geofence_draw_mode.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/create/geofence_create_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/app_button.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/widgets/geofence_draw_toolbar.dart';
import 'package:nusantara_gps/presentation/widgets/rounded_text_field.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/widgets/alert_type_selector.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/widgets/vehicle_multi_select.dart';
import 'package:nusantara_gps/presentation/widgets/common/info_tile.dart';
import 'package:provider/provider.dart';

class GeofenceCreateScreen extends StatefulWidget {
  const GeofenceCreateScreen({super.key});

  @override
  State<GeofenceCreateScreen> createState() => _GeofenceCreateScreenState();
}

class _GeofenceCreateScreenState extends State<GeofenceCreateScreen> {
  static const LatLng _defaultCenter = LatLng(-7.936738, 112.617612);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeofenceCreateViewModel>().loadVehicles();
    });
  }

  Future<void> _onSave() async {
    final vm = context.read<GeofenceCreateViewModel>();

    if (vm.nameController.text.trim().isEmpty) {
      _snack('Nama pagar tidak boleh kosong');
      return;
    }
    if (!vm.drawManager.isAreaReady) {
      _snack('Area geofence belum selesai digambar');
      return;
    }

    await vm.saveGeofence();
    if (!mounted) return;

    if (vm.saveGeofenceState == ResultState.success) {
      _snack('Geofence berhasil disimpan', isError: false);
      Navigator.of(context).pop(true);
    } else {
      _snack(vm.errorMessage ?? 'Gagal menyimpan geofence');
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
    final vm = context.watch<GeofenceCreateViewModel>();
    // ListenableBuilder agar rebuild saat drawManager berubah
    return ListenableBuilder(
      listenable: vm.drawManager,
      builder: (context, _) {
        final dm = vm.drawManager;

        return Scaffold(
          appBar: AppBar(
            title: Text('Tambah Pagar Virtual', style: AppTextTheme.titleMedium),
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
                      initialCameraPosition: const CameraPosition(
                        target: _defaultCenter,
                        zoom: 13,
                      ),
                      // Nonaktifkan scroll saat mode gambar
                      scrollGesturesEnabled: dm.drawMode == GeofenceDrawMode.pan,
                      zoomGesturesEnabled: true,
                      onTap: dm.drawMode != GeofenceDrawMode.pan
                          ? dm.onMapTap
                          : null,
                      circles:  dm.previewCircles,
                      polygons: {...dm.previewRectangle, ...dm.previewPolygon},
                      markers:  dm.polygonMarkers,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                    ),

                    // Toolbar kiri atas 
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GeofenceDrawToolbar(
                        selected: dm.drawMode,
                        onModeChanged: dm.setDrawMode,
                      ),
                    ),

                    // Hint instruksi 
                    Positioned(
                      top: 12,
                      left: 180,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Text(
                          dm.hintText,
                          style: AppTextTheme.bodySmall,
                          maxLines: 2,
                        ),
                      ),
                    ),

                    // Tombol aksi polygon
                    if (dm.drawMode == GeofenceDrawMode.polygon)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            if (dm.polygonPoints.isNotEmpty && !dm.isPolygonClosed)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: dm.removeLastPolygonPoint,
                                  icon: const Icon(Icons.undo_rounded, size: 16),
                                  label: const Text('Undo'),
                                  style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white),
                                ),
                              ),
                            if (dm.polygonPoints.length >= 3 &&
                                !dm.isPolygonClosed) ...[
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
                                  onPressed: () =>
                                      dm.setDrawMode(GeofenceDrawMode.polygon),
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 16),
                                  label: const Text('Gambar Ulang'),
                                  style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Reset rectangle
                    if (dm.drawMode == GeofenceDrawMode.rectangle &&
                        dm.rectStart != null &&
                        dm.rectEnd != null)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: OutlinedButton.icon(
                          onPressed: dm.resetRectangle,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Gambar Ulang'),
                          style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white),
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

                      // Nama
                      Text('Nama Pagar', style: AppTextTheme.labelMedium),
                      const SizedBox(height: 6),
                      RoundedTextField(
                        controller: vm.nameController,
                        hint: 'Contoh: Area Gudang Surabaya',
                        icon: Icons.edit_location_rounded,
                      ),

                      // Radius — hanya tampil saat mode circle
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

                      // Jenis pagar virtual
                      Text('Jenis pagar virtual',
                          style: AppTextTheme.labelMedium),
                      const SizedBox(height: 8),
                      AlertTypeSelector(
                        selected: vm.alertType,
                        onChanged: vm.setAlertType,
                      ),

                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 18),

                      // Set ke armada
                      Text('Set ke armada', style: AppTextTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih kendaraan yang akan dipantau geofence ini',
                        style: AppTextTheme.bodySmall
                            ?.copyWith(color: AppColorTheme.gray400),
                      ),
                      const SizedBox(height: 10),

                      switch (vm.loadVehicleState) {
                        ResultState.loading => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CupertinoActivityIndicator(),
                            ),
                          ),
                        ResultState.error  => InfoTile(
                            icon: Icons.error_outline,
                            color: AppColorTheme.red500,
                            bgColor: AppColorTheme.red50,
                            borderColor: AppColorTheme.red200,
                            text: 'Gagal memuat daftar kendaraan',
                          ),
                        ResultState.noData => InfoTile(
                            icon: Icons.directions_car_outlined,
                            color: AppColorTheme.gray400,
                            bgColor: AppColorTheme.gray50,
                            borderColor: AppColorTheme.gray200,
                            text: 'Tidak ada kendaraan tersedia',
                          ),
                        ResultState.success => VehicleMultiSelect(
                            vehicles: vm.vehicles,
                            selectedIds: vm.selectedIds,
                            onToggle: vm.toggleVehicle,
                          ),
                        _ => const SizedBox.shrink(),
                      },

                      const SizedBox(height: 24),

                      // Tombol simpan
                      SizedBox(
                        width: double.infinity,
                        child: vm.saveGeofenceState == ResultState.loading
                            ? const Center(child: CupertinoActivityIndicator())
                            : AppButton(
                                label: 'Simpan',
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
