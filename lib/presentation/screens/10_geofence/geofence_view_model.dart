import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/core/utils/geofence_utils.dart';
import 'package:nusantara_gps/data/models/device.dart';
import 'package:nusantara_gps/data/models/geofence_model.dart';
import 'package:nusantara_gps/data/models/position.dart';
import 'package:nusantara_gps/domain/interfaces/i_tracking_repository.dart';
import 'package:nusantara_gps/domain/interfaces/i_vehicle_repository.dart';

class GeofenceViewModel extends ChangeNotifier {
  final IVehicleRepository _repo;
  final ITrackingRepository _trackingRepo;

  GeofenceViewModel(this._repo, this._trackingRepo);

  ResultState _loadGeofenceState = ResultState.initial;
  String? _errorMessage;

  ResultState get loadGeofenceState => _loadGeofenceState;
  String? get errorMessage => _errorMessage;

  ResultState _deleteGeofenceState = ResultState.initial;
  ResultState get deleteGeofenceState => _deleteGeofenceState;

  List<GeofenceModel> geofenceData = [];

  GeofenceModel? _selectedGeofence;
  GeofenceModel? get selectedGeofence => _selectedGeofence;

  MapType _mapType = MapType.normal;
  MapType get mapType => _mapType;

  GoogleMapController? _controller;

  // simpan "pending recenter" jika controller belum siap saat load selesai
  List<LatLng>? _pendingRecenter;

  // Device markers
  Map<int, Device> _devices = {};
  Map<int, PositionModel> _positions = {};
  final Map<String, BitmapDescriptor> _iconCache = {};

  bool _showDeviceMarkers = true;
  bool get showDeviceMarkers => _showDeviceMarkers;

  void toggleDeviceMarkers() {
    _showDeviceMarkers = !_showDeviceMarkers;
    notifyListeners();
  }

  // Preload vehicle status icons agar marker bisa langsung pakai.
  Future<void> _initMarkerIcons() async {
    for (final pos in _positions.values) {
      final assetPath = pos.status.iconAsset;
      if (!_iconCache.containsKey(assetPath)) {
        _iconCache[assetPath] = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(72, 72)),
          assetPath,
        );
      }
    }
  }

  // Menghasilkan marker set dari posisi device terakhir.
  Set<Marker> get deviceMarkers {
    if (!_showDeviceMarkers) return {};

    return _positions.entries.map((entry) {
      final pos = entry.value;
      final device = _devices[pos.deviceId];
      final icon =
          _iconCache[pos.status.iconAsset] ?? BitmapDescriptor.defaultMarker;

      return Marker(
        markerId: MarkerId('dev_${pos.deviceId}'),
        position: LatLng(pos.latitude, pos.longitude),
        icon: icon,
        rotation: pos.course,
        flat: true,
        infoWindow: InfoWindow(
          title: device?.name ?? 'Device ${pos.deviceId}',
        ),
        anchor: const Offset(0.5, 0.5),
      );
    }).toSet();
  }

  // Load devices & positions dari tracking API.
  Future<void> loadDevices() async {
    try {
      final deviceList = await _trackingRepo.getTrackedDevices();
      _devices = {for (final d in deviceList) d.id: d};

      final posList = await _trackingRepo.getPosition();
      _positions = {for (final p in posList) p.deviceId: p};

      await _initMarkerIcons();
      notifyListeners();
    } catch (_) {
      // Gagal load device tidak blocking — geofence tetap tampil.
    }
  }
  // End Device markers
  void setMapController(GoogleMapController controller) {
    _controller = controller;

    // jika ada pending recenter (data sudah datang sebelum controller siap),
    // langsung jalankan sekarang
    if (_pendingRecenter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        recenterGeofence(_pendingRecenter!);
        _pendingRecenter = null;
      });
    }

    notifyListeners();
  }

  void setSelectedGeoFence(GeofenceModel geofence) {
    _selectedGeofence = geofence;
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      recenterGeofence(geofence.polygon);
    });
  }

  void changeMapType(MapType type) {
    _mapType = type;
    notifyListeners();
  }

  Future<void> loadGeofence() async {
    _loadGeofenceState = ResultState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repo.getGeofenceArea();

      if (data.isEmpty) {
        geofenceData = [];
        _selectedGeofence = null;
        _loadGeofenceState = ResultState.noData;
      } else {
        geofenceData = data;
        _selectedGeofence = data.first;
        _loadGeofenceState = ResultState.success;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller != null) {
            // Controller sudah siap, langsung recenter
            recenterGeofence(_selectedGeofence!.polygon);
          } else {
            _pendingRecenter = _selectedGeofence!.polygon;
          }
        });
      }
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _loadGeofenceState = ResultState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _loadGeofenceState = ResultState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteGeofence(int id) async {
    _deleteGeofenceState = ResultState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.deleteGeofence(id: id);
      _deleteGeofenceState = ResultState.success;
      await loadGeofence();
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _deleteGeofenceState = ResultState.error;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _deleteGeofenceState = ResultState.error;
      notifyListeners();
    }
  }

  Set<Polygon> get allPolygons {
    return geofenceData.map((item) {
      final isSelected = _selectedGeofence?.id == item.id;

      return Polygon(
        polygonId: PolygonId(item.id.toString()),
        points: item.polygon,
        strokeWidth: isSelected ? 3 : 2,
        strokeColor: isSelected ? Colors.red : Colors.blueGrey,
        fillColor: (isSelected ? Colors.red : Colors.blueGrey).withAlpha(35),
      );
    }).toSet();
  }

  Set<Polygon> get polygons {
    if (_selectedGeofence == null) return {};

    return {
      Polygon(
        polygonId: PolygonId(_selectedGeofence!.id.toString()),
        points: _selectedGeofence!.polygon,
        strokeWidth: 2,
        strokeColor: Colors.red,
        fillColor: Colors.red.withAlpha(20),
      ),
    };
  }

  void recenterGeofence(List<LatLng> geofencePoints) {
    if (geofencePoints.isEmpty || _controller == null) return;

    final bounds = GeofenceUtils.getBounds(geofencePoints);
    _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0),
    );
  }
}