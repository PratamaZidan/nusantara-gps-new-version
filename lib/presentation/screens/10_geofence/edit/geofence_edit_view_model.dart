import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/data/models/vehicle_model.dart';
import 'package:nusantara_gps/domain/entities/geofence_draw_mode.dart';
import 'package:nusantara_gps/domain/event/data_invalidation_bus.dart';
import 'package:nusantara_gps/domain/interfaces/i_vehicle_repository.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/helpers/geofence_draw_manager.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/helpers/geofence_payload_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GeofenceAlertTypeEdit { enter, exit }

class GeofenceEditViewModel extends ChangeNotifier {
  final IVehicleRepository _repo;
  final DataInvalidationBus _bus;
  final int geofenceId;

  GeofenceEditViewModel(this._repo, this._bus, {required this.geofenceId});

  final drawManager = GeofenceDrawManager();
  final nameController = TextEditingController();
  final radiusController = TextEditingController(text: '100');

  // Load state
  ResultState _loadState = ResultState.loading;
  ResultState get loadState => _loadState;

  // Save state
  ResultState _updateGeofenceState = ResultState.initial;
  ResultState get updateGeofenceState => _updateGeofenceState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Jenis alert
  GeofenceAlertTypeEdit _alertType = GeofenceAlertTypeEdit.enter;
  GeofenceAlertTypeEdit get alertType => _alertType;

  void setAlertType(GeofenceAlertTypeEdit type) {
    _alertType = type;
    notifyListeners();
  }

  // Daftar kendaraan
  ResultState _loadVehicleState = ResultState.initial;
  ResultState get loadVehicleState => _loadVehicleState;

  List<Vehicle> _vehicles = [];
  List<Vehicle> get vehicles => _vehicles;

  final Set<String> _selectedIds = {};
  Set<String> get selectedIds => _selectedIds;

  bool isVehicleSelected(String id) => _selectedIds.contains(id);

  void toggleVehicle(String id) {
    _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    notifyListeners();
  }

  // Storage key per geofence
  String get _storageKey => 'geofence_vehicles_$geofenceId';

  // Baca vehicle IDs yang tersimpan lokal untuk geofence ini
  Future<Set<String>> _loadSavedVehicleIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  // Simpan vehicle IDs yang dipilih ke storage lokal
  Future<void> _saveVehicleIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(ids.toList()));
  }

  // Load

  Future<void> loadVehicles() async {
    _loadVehicleState = ResultState.loading;
    notifyListeners();
    try {
      _vehicles = await _repo.getVehicles(searchQuery: '', page: 1);
      _loadVehicleState = _vehicles.isEmpty ? ResultState.noData : ResultState.success;
    } catch (_) {
      _loadVehicleState = ResultState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadGeofence() async {
    _loadState = ResultState.loading;
    notifyListeners();

    try {
      final data = await _repo.getGeofenceById(geofenceId);
      if (data == null) {
        _loadState = ResultState.error;
        _errorMessage = 'Data geofence tidak ditemukan';
        notifyListeners();
        return;
      }

      nameController.text = data.name;

      _selectedIds.clear();
      final savedIds = await _loadSavedVehicleIds();

      if (savedIds.isNotEmpty) {
        // Gunakan data lokal — pastikan vehicle masih ada di daftar
        for (final id in savedIds) {
          final exists = _vehicles.any((v) => v.id == id);
          if (exists) _selectedIds.add(id);
        }
      } else if (data.deviceIds.isNotEmpty) {
        // Fallback: coba match dari API (untuk kompatibilitas)
        for (final id in data.deviceIds) {
          final match = _vehicles.firstWhere(
            (v) => v.id == id || v.emei.replaceAll(' ', '') == id.replaceAll(' ', ''),
            orElse: () => Vehicle(
              id: '', brand: '', plateNumber: '',
              status: VehicleStatus.down, emei: '', gsm: '', model: '', imageUrl: '',
            ),
          );
          if (match.id.isNotEmpty) _selectedIds.add(match.id);
        }
      }

      // Prefill alertType dari data API
      _alertType = (data.inout == '1')
          ? GeofenceAlertTypeEdit.enter
          : GeofenceAlertTypeEdit.exit;

      // Prefill bentuk geofence
      if (data.isCircle) {
        if (data.centerLat != null && data.centerLng != null) {
          drawManager.setCircleCenter(LatLng(data.centerLat!, data.centerLng!));
        }
        final r = data.radiusMeters ?? 100.0;
        drawManager.updateRadius(r);
        radiusController.text = r.toStringAsFixed(0);
        drawManager.initDrawMode(GeofenceDrawMode.circle);

      } else if (data.isRectangle) {
        if (data.polygon.length >= 3) {
          drawManager.onMapTap(data.polygon[0]);
          drawManager.onMapTap(data.polygon[2]);
        }
        drawManager.initDrawMode(GeofenceDrawMode.rectangle);

      } else {
        for (final p in data.polygon) {
          drawManager.addPolygonPoint(p);
        }
        if (!drawManager.isPolygonClosed && drawManager.polygonPoints.length >= 3) {
          drawManager.closePolygon();
        }
        drawManager.initDrawMode(GeofenceDrawMode.polygon);
      }

      _loadState = ResultState.success;
    } catch (e) {
      _loadState = ResultState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // Radius sync
  void onRadiusChanged(String value) {
    final r = double.tryParse(value);
    if (r != null) drawManager.updateRadius(r);
  }

  // Simpan
  Future<void> updateGeofence() async {
    _updateGeofenceState = ResultState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final deviceIdsMapped = _selectedIds.map((id) {
        final vehicle = _vehicles.firstWhere(
          (v) => v.id == id,
          orElse: () => Vehicle(
            id: '', brand: '', plateNumber: '',
            status: VehicleStatus.down, emei: id, gsm: '', model: '', imageUrl: '',
          ),
        );
        return vehicle.emei.replaceAll(' ', '');
      }).toList();

      final payload = GeofencePayloadBuilder.buildUpdate(
        id: geofenceId,
        mode: drawManager.drawMode,
        name: nameController.text.trim(),
        notif: _alertType == GeofenceAlertTypeEdit.enter ? 'in' : 'out',
        deviceIds: deviceIdsMapped,
        circleCenter: drawManager.circleCenter,
        radius: drawManager.circleRadius,
        rectStart: drawManager.rectStart,
        rectEnd: drawManager.rectEnd,
        polygonPoints: drawManager.polygonPoints,
      );

      await _repo.createGeofenceRaw(payload: payload);

      // Simpan pilihan kendaraan ke storage lokal
      await _saveVehicleIds(_selectedIds);

      _updateGeofenceState = ResultState.success;
      _bus.emit(DataInvalidationEvent.geofenceChanged);
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _updateGeofenceState = ResultState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _updateGeofenceState = ResultState.error;
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    radiusController.dispose();
    drawManager.dispose();
    super.dispose();
  }
}