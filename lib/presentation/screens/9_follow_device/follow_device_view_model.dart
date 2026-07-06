import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/distance_util.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/data/models/device.dart';
import 'package:nusantara_gps/data/models/location_status.dart';
import 'package:nusantara_gps/data/models/position.dart';
import 'package:nusantara_gps/domain/interfaces/i_location_service.dart';
import 'package:nusantara_gps/domain/interfaces/i_tracking_repository.dart';

class FollowDeviceViewModel extends ChangeNotifier {
  final ITrackingRepository _trackingRepo;
  final ILocationService _locationService;
  FollowDeviceViewModel(this._trackingRepo, this._locationService);
  static const tag = 'FollowDeviceViewModel: ';

  ResultState _loadTrackingDataState = ResultState.initial;
  String? _errorMessage;

  ResultState get loadTrackingDataState => _loadTrackingDataState;
  String? get errorMessage => _errorMessage;

  PositionModel? position;
  Device? device;

  LocationStatus _myLocationStatus = LocationStatus.initial;
  LocationStatus get myLocationStatus => _myLocationStatus;

  StreamSubscription<Position>? _positionSubscription;

  String? _myLocationErrorMessage;
  String? get myLocationErrorMessage => _myLocationErrorMessage;

  LatLng? _currentLatLng;
  LatLng? get currentLatLng => _currentLatLng;

  Future<void> initialDevice(int deviceId) async {
    try {
      device = await _trackingRepo.getDeviceById(id: deviceId);
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
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

  void startPolling(int deviceId) {
    _loadTrackingDataState = ResultState.loading;
    notifyListeners();
    Future.doWhile(() async {
      try {
        final positions = await _trackingRepo.getPosition(
          deviceId: deviceId.toString(),
        );
        if (positions.isNotEmpty) {
          _loadTrackingDataState = ResultState.success;
          position = positions.first;
        } else {
          _loadTrackingDataState = ResultState.noData;
        }
        getAddress(deviceId);
        notifyListeners();
        recenterVehicleLocation();
        await Future.delayed(Duration(seconds: 10));
        return true;
      } on DioException catch (e) {
        _errorMessage = mapDioErrorToMessage(e);
        _loadTrackingDataState = ResultState.error;
        notifyListeners();
        return false;
      }
    });
  }

  String _selectedDeviceAddress = '';
  String get selectedDeviceAddress => _selectedDeviceAddress;

  Future<void> getAddress(int deviceId) async {
    try {
      final lat = position?.latitude ?? 0;
      final lng = position?.longitude ?? 0;
      final data = await _trackingRepo.getAddress(lat: lat, lng: lng);
      _selectedDeviceAddress = data;
    } catch (e) {
      _loadTrackingDataState = ResultState.error;
      _selectedDeviceAddress = 'failed get adress';
    } finally {
      _loadTrackingDataState = ResultState.success;
      notifyListeners();
    }
  }

  Set<Marker> buildMarkers(PositionModel? p) {
    return <Marker>{
      Marker(
        markerId: MarkerId('1'),
        position: LatLng(p?.latitude ?? 0, p?.longitude ?? 0),
        rotation: p?.course ?? 0,
        icon: _getMarkerIcon(p?.status ?? VehicleStatus.down),
      ),
    };
  }

  double _distance = 0.0;
  double get distance {
    _distance = distanceInMeters(
      lat1: _currentLatLng?.latitude ?? 0,
      lon1: currentLatLng?.longitude ?? 0,
      lat2: position?.latitude ?? 0,
      lon2: position?.longitude ?? 0,
    );
    return _distance;
  }

  Set<Polyline> get polylines {
    if (position == null) return {};
    final polyPoints = [
      LatLng(position?.latitude ?? 0, position?.longitude ?? 0),
      _currentLatLng ?? LatLng(0, 0),
    ];
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: polyPoints,
        width: 4,
        color: position?.status.color.withAlpha(50) ?? Colors.transparent,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  final Map<String, BitmapDescriptor> _markerIconCache = {};

  BitmapDescriptor _getMarkerIcon(VehicleStatus status) {
    final assetPath = status.iconAsset;
    final cached = _markerIconCache[assetPath];
    if (cached != null) return cached;

    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(72, 72)),
      assetPath,
    ).then((descriptor) {
      _markerIconCache[assetPath] = descriptor;
      notifyListeners();
    });
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }

  GoogleMapController? _controller;

  void setMapController(GoogleMapController controller) {
    _controller = controller;
    notifyListeners();
  }

  MapType _mapType = MapType.normal;
  MapType get mapType => _mapType;

  void changeMapType(MapType type) {
    _mapType = type;
    notifyListeners();
  }

  void recenterSelfLocation() {
    recenterCamera(
      _currentLatLng?.latitude ?? 0,
      _currentLatLng?.longitude ?? 0,
    );
  }

  void recenterVehicleLocation() {
    recenterCamera(position?.latitude ?? 0, position?.longitude ?? 0);
  }

  void recenterCamera(double lat, double long) {
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, long), zoom: 17),
      ),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
