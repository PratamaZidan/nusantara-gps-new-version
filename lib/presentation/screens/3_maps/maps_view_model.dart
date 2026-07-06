import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide Polygon;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/cluster_manager.dart';
import 'package:nusantara_gps/core/utils/cluster_marker_painter.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/data/models/device.dart';
import 'package:nusantara_gps/data/models/geofence_model.dart';
import 'package:nusantara_gps/data/models/location_status.dart';
import 'package:nusantara_gps/data/models/position.dart';
import 'package:nusantara_gps/domain/entities/map_type.dart';
import 'package:nusantara_gps/domain/interfaces/i_location_service.dart';
import 'package:nusantara_gps/domain/interfaces/i_maps_repository.dart';
import 'package:nusantara_gps/domain/interfaces/i_tracking_repository.dart';
import 'package:nusantara_gps/domain/interfaces/i_vehicle_repository.dart';

class MapsViewModel extends ChangeNotifier {
  final ITrackingRepository _trackingRepo;
  final IMapsRepository _mapsRepo;
  final ILocationService _locationService;
  final IVehicleRepository _vehicleRepo;

  MapsViewModel(
    this._trackingRepo,
    this._mapsRepo,
    this._locationService,
    this._vehicleRepo,
  );

  Map<int, Device> devices = {};
  Map<int, PositionModel> positions = {};
  final Map<int, String> _deviceAddresses = {};

  GoogleMapController? _controller;
  MapController mapController = MapController();

  LatLng _initialPosition = const LatLng(0, 0);
  LatLng get initialPosition => _initialPosition;

  LocationStatus _myLocationStatus = LocationStatus.initial;
  LocationStatus get myLocationStatus => _myLocationStatus;

  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentLatLng;
  LatLng? get currentLatLng => _currentLatLng;

  MapType _mapType = MapType.normal;
  MapType get mapType => _mapType;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _myLocationErrorMessage;
  String? get myLocationErrorMessage => _myLocationErrorMessage;

  bool _mapLoading = false;
  bool get mapLoading => _mapLoading;

  ResultState _loadTrackingDataState = ResultState.initial;
  ResultState get loadTrackingDataState => _loadTrackingDataState;

  Map<VehicleStatus, int> statusCounts = {};

  VehicleStatus? _filterStatus;
  VehicleStatus? get filterStatus => _filterStatus;

  MapSource _mapSource = MapSource.google;
  MapSource get mapSource => _mapSource;

  final Map<String, BitmapDescriptor> _iconCache = {};

  // Clustering
  double _currentZoom = 12.0;
  double get currentZoom => _currentZoom;

  List<MarkerCluster> _clusters = [];
  List<MarkerCluster> get clusters => _clusters;

  final Map<int, BitmapDescriptor> _clusterIconCache = {};

  void onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;
    // Tidak rebuild di sini agar tidak lag saat drag
  }

  void onCameraIdle() {
    _rebuildClusters();
    notifyListeners();
  }

  void _rebuildClusters() {
  _clusters = CustomClusterManager.cluster(
    positions: positions,
    zoom: _currentZoom,
  );
}

  Future<BitmapDescriptor> getClusterIcon(int count) async {
    if (_clusterIconCache.containsKey(count)) {
      return _clusterIconCache[count]!;
    }
    final icon = await ClusterMarkerPainter.createClusterIcon(count);
    _clusterIconCache[count] = icon;
    return icon;
  }

  // Geofence Overlay
  List<GeofenceModel> _geofenceList = [];

  bool _showGeofenceOverlay = false;
  bool get showGeofenceOverlay => _showGeofenceOverlay;

  ResultState _geofenceOverlayState = ResultState.initial;
  ResultState get geofenceOverlayState => _geofenceOverlayState;

  void toggleGeofenceOverlay() {
    _showGeofenceOverlay = !_showGeofenceOverlay;
    notifyListeners();
  }

  Future<void> loadGeofenceOverlay() async {
    if (_geofenceOverlayState == ResultState.loading) return;
    _geofenceOverlayState = ResultState.loading;

    try {
      final list = await _vehicleRepo.getGeofenceArea();
      _geofenceList = list;
      _geofenceOverlayState = ResultState.success;
    } catch (_) {
      _geofenceOverlayState = ResultState.error;
    }
    notifyListeners();
  }

  Set<Polygon> get geofencePolygons {
    if (!_showGeofenceOverlay) return {};
    return _geofenceList.map((g) => Polygon(
          polygonId: PolygonId('geofence_${g.id}'),
          points: g.polygon,
          strokeWidth: 2,
          strokeColor: Colors.red.withAlpha(180),
          fillColor: Colors.red.withAlpha(30),
        )).toSet();
  }

  // Status Counts
  void _calculateStatusCounts() {
    statusCounts.clear();

    // Hitung device yang punya posisi
    for (final pos in positions.values) {
      final status = pos.status;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    // Device yang tidak punya posisi dianggap down
    final downCount = devices.values.where((d) => !positions.containsKey(d.id)).length;

    statusCounts[VehicleStatus.down] = downCount;
  }

  PositionModel? getPositionByDeviceId(int deviceId) => positions[deviceId];
  String? getAddressByDeviceId(int deviceId) => _deviceAddresses[deviceId];

  // Load Initial
  Future<void> loadInitial() async {
    _loadTrackingDataState = ResultState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final deviceList = await _trackingRepo.getTrackedDevices();
      for (final d in deviceList) devices[d.id] = d;

      final posList = await _trackingRepo.getPosition();
      for (final p in posList) positions[p.deviceId] = p;

      _calculateStatusCounts();
      _rebuildClusters();
      _loadTrackingDataState = ResultState.success;
      notifyListeners();

      _startPolling();
      loadGeofenceOverlay();
      init();
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _loadTrackingDataState = ResultState.error;
      notifyListeners();
    }
  }

  // Polling Optimized
  void _startPolling() {
    Future.doWhile(() async {
      try {
        await Future.delayed(const Duration(seconds: 15));

        final posList = await _trackingRepo.getPosition();
        bool hasChange = false;

        for (final p in posList) {
          final existing = positions[p.deviceId];
          if (existing == null ||
              existing.latitude != p.latitude ||
              existing.longitude != p.longitude ||
              existing.status != p.status) {
            positions[p.deviceId] = p;
            hasChange = true;
          }
        }

        // Tandai device yang udah ga muncul sama sekali di hasil polling
        for (final id in positions.keys) {
          final stillPresent = posList.any((p) => p.deviceId == id);
          if (!stillPresent && positions[id]?.status != VehicleStatus.down) {
            positions[id] = _markAsDown(positions[id]!);
            hasChange = true;
          }
        }

        if (hasChange) {
          _calculateStatusCounts();
          _rebuildClusters();
          notifyListeners();
        }

        return true;
      } on DioException catch (e) {
        _errorMessage = mapDioErrorToMessage(e);
        _loadTrackingDataState = ResultState.error;
        notifyListeners();
        return false;
      }
    });
  }

  // Buat salinan PoisitionModel dengan status down
  PositionModel _markAsDown(PositionModel p) => PositionModel(
    deviceId: p.deviceId,
    latitude: p.latitude,
    longitude: p.longitude,
    course: p.course,
    sat: p.sat,
    address: p.address,
    status: VehicleStatus.down,
    speed: 0,
    totalDistance: p.totalDistance,
    voltageLevel: p.voltageLevel,
    batteryPercent: p.batteryPercent,
    deviceTime: p.deviceTime,
    fixTime: p.fixTime,
    serverTimeUTC: p.serverTimeUTC,
  );

  Future<void> getAddress(int deviceId) async {
    try {
      final position = positions[deviceId];
      if (position == null) return;

      final data = await _trackingRepo.getAddress(
          lat: position.latitude, lng: position.longitude);
      _deviceAddresses[deviceId] = data;
    } catch (_) {
      _deviceAddresses[deviceId] = 'failed get address';
    } finally {
      notifyListeners();
    }
  }

  Future<void> initMap() async {
    _mapLoading = true;
    notifyListeners();

    final location = await _mapsRepo.getInitialLocation();
    _initialPosition = LatLng(location["lat"]!, location["lng"]!);

    _mapLoading = false;
    notifyListeners();
  }

  Future<void> initMarkers() async {
    for (final v in positions.values) {
      if (!_iconCache.containsKey(v.status.iconAsset)) {
        final icon = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(48, 48)),
          v.status.iconAsset,
        );
        _iconCache[v.status.iconAsset] = icon;
      }
    }
    notifyListeners();
  }

  BitmapDescriptor getIcon(String assetPath) =>
      _iconCache[assetPath] ?? BitmapDescriptor.defaultMarker;

  void onMapCreated(GoogleMapController controller) => _controller = controller;
  void setMapController(GoogleMapController controller) =>
      _controller = controller;

  void changeMapType(MapType type) {
    _mapType = type;
    notifyListeners();
  }

  void changeMapSource(MapSource source) {
    _mapSource = source;
    notifyListeners();
  }

  Future<void> init() async {
    _myLocationStatus = LocationStatus.requestingPermission;
    notifyListeners();

    final ok = await _locationService.requestPermissionAndCheckService();
    if (!ok) {
      _myLocationStatus = LocationStatus.permissionDenied;
      _myLocationErrorMessage =
          'Izin lokasi ditolak atau layanan lokasi nonaktif. Aktifkan di pengaturan.';
      notifyListeners();
      return;
    }

    _startTracking();
  }

  void _startTracking() {
    _myLocationStatus = LocationStatus.tracking;
    notifyListeners();

    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen(
      (position) {
        _currentLatLng = LatLng(position.latitude, position.longitude);
        notifyListeners();
      },
      onError: (e) {
        _myLocationStatus = LocationStatus.error;
        _myLocationErrorMessage = 'Gagal mendapatkan lokasi: $e';
        notifyListeners();
      },
    );
  }

  void recenterSelfLocation() async {
  if (_currentLatLng == null) {
    await init();
    await Future.delayed(const Duration(seconds: 2));
  }
  if (_currentLatLng == null) return; // masih null = GPS tidak tersedia
  recenterCamera(_currentLatLng!.latitude, _currentLatLng!.longitude);
}

  void recenterCamera(double lat, double long) {
    if (mapSource == MapSource.google) {
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, long), zoom: 15),
        ),
      );
    } else {
      mapController.move(latlong2.LatLng(lat, long), 15);
    }
    notifyListeners();
  }

  Map<int, PositionModel> get filteredPositions {
    if (_filterStatus == null) return positions;
    return Map.fromEntries(
      positions.entries.where((entry) => entry.value.status == _filterStatus),
    );
  }

  List<Device> get downDevices {
    return devices.values
        .where((d) => !positions.containsKey(d.id))
        .toList();
  }

  void setFilterStatus(VehicleStatus? status) {
    _filterStatus = (_filterStatus == status) ? null : status;
    _rebuildClusters();
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}