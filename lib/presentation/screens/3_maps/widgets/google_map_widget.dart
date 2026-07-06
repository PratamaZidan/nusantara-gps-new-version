import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/utils/cluster_marker_painter.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/maps_view_model.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/widgets/vehicle_info_bottom_sheet.dart';
import 'package:provider/provider.dart';

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({super.key});

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  final Map<String, BitmapDescriptor> _vehicleIconCache = {};
  final Map<int, BitmapDescriptor> _clusterIconCache = {};

  Set<Marker> _currentMarkers = {};
  bool _buildingMarkers = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<MapsViewModel>(
      builder: (context, viewModel, child) {
        final center =
            viewModel.currentLatLng ?? const LatLng(-7.936738, 112.617612);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _refreshMarkers(viewModel);
          }
        });

        return GoogleMap(
          zoomControlsEnabled: false,
          mapType: viewModel.mapType,
          initialCameraPosition: CameraPosition(target: center, zoom: 12),
          onMapCreated: (controller) {
            viewModel.setMapController(controller);
            _refreshMarkers(viewModel);
          },
          onCameraMove: viewModel.onCameraMove,
          onCameraIdle: () {
            viewModel.onCameraIdle();
            // _refreshMarkers(viewModel);
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          markers: _currentMarkers,
          polygons: viewModel.geofencePolygons,
        );
      },
    );
  }

  void _refreshMarkers(MapsViewModel vm) {
    _clusterIconCache.clear();
    if (_buildingMarkers) return;
    _buildingMarkers = true;
    _buildClusterMarkers(vm).then((markers) {
      if (!mounted) return;
      setState(() {
        _currentMarkers = markers;
        _buildingMarkers = false;
      });
    });
  }

  Future<Set<Marker>> _buildClusterMarkers(MapsViewModel vm) async {
    final Set<Marker> markers = {};
    final clusters = vm.clusters;

    if (clusters.isEmpty) return _buildRawMarkers(vm);

    for (final cluster in clusters) {
      if (cluster.isSingle) {
        // Marker tunggal
        final deviceId = cluster.deviceIds.first;
        final position = vm.positions[deviceId];
        if (position == null) continue;

        if (vm.filterStatus != null && position.status != vm.filterStatus) {
          continue;
        }

        final device = vm.devices[deviceId];
        final icon   = await _getVehicleIcon(position.status);

        markers.add(Marker(
          markerId: MarkerId('v_$deviceId'),
          position: cluster.position,
          rotation: position.course,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: icon,
          infoWindow: InfoWindow(
            title: device?.name ?? 'Kendaraan',
            snippet: 'Speed: ${position.speed.toStringAsFixed(0)} km/h',
            onTap: () async {
              await vm.getAddress(deviceId);
              if (!mounted) return;
              showVehicleSheet(context, device!);
            },
          ),
        ));
      } else {
        final visibleCount = vm.filterStatus == null
            ? cluster.count
            : cluster.deviceIds.where((id) {
                final pos = vm.positions[id];
                return pos != null && pos.status == vm.filterStatus;
              }).length;

        // Jika semua kendaraan di cluster ini ter-filter, skip
        if (visibleCount == 0) continue;

        final icon = await _getClusterIcon(visibleCount);

        markers.add(Marker(
          markerId: MarkerId(
              'c_${cluster.position.latitude}_${cluster.position.longitude}'),
          position: cluster.position,
          icon: icon,
          onTap: () {
            vm.recenterCamera(
              cluster.position.latitude,
              cluster.position.longitude,
            );
          },
        ));
      }
    }

    return markers;
  }

  // Fallback marker biasa (tanpa clustering) — dipakai saat cluster belum siap
  Set<Marker> _buildRawMarkers(MapsViewModel vm) {
    return vm.filteredPositions.entries.take(50).map((e) {
      final pos    = e.value;
      final device = vm.devices[e.key];
      return Marker(
        markerId: MarkerId('v_${e.key}'),
        position: LatLng(pos.latitude, pos.longitude),
        rotation: pos.course,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: _getVehicleIconSync(pos.status),
        infoWindow: InfoWindow(
          title:   device?.name ?? 'Kendaraan',
          snippet: 'Speed: ${pos.speed.toStringAsFixed(0)} km/h',
        ),
      );
    }).toSet();
  }

  // Icon helpers
  Future<BitmapDescriptor> _getVehicleIcon(VehicleStatus status) async {
    final path = status.iconAsset;
    if (_vehicleIconCache.containsKey(path)) return _vehicleIconCache[path]!;
    final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(72, 72)), path);
    _vehicleIconCache[path] = icon;
    return icon;
  }

  BitmapDescriptor _getVehicleIconSync(VehicleStatus status) {
    final path = status.iconAsset;
    if (_vehicleIconCache.containsKey(path)) return _vehicleIconCache[path]!;
    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(72, 72)),
      path,
    ).then((icon) {
      if (!mounted) return;
      setState(() => _vehicleIconCache[path] = icon);
    });
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }

  Future<BitmapDescriptor> _getClusterIcon(int count) async {
    final key = count;
    if (_clusterIconCache.containsKey(key)) return _clusterIconCache[key]!;
    final icon = await ClusterMarkerPainter.createClusterIcon(count);
    _clusterIconCache[key] = icon;
    return icon;
  }
}