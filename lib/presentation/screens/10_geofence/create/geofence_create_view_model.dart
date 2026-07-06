import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/data/models/vehicle_model.dart';
import 'package:nusantara_gps/domain/event/data_invalidation_bus.dart';
import 'package:nusantara_gps/domain/interfaces/i_vehicle_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nusantara_gps/presentation/screens/10_geofence/helpers/geofence_draw_manager.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/helpers/geofence_payload_builder.dart';

enum GeofenceAlertType { enter, exit }

class GeofenceCreateViewModel extends ChangeNotifier {
  final IVehicleRepository _repo;
  final DataInvalidationBus _bus;

  GeofenceCreateViewModel(this._repo, this._bus);

  final drawManager = GeofenceDrawManager();
  final nameController = TextEditingController();
  final radiusController = TextEditingController(text: '100');

  // Save state
  ResultState _saveGeofenceState = ResultState.initial;
  ResultState get saveGeofenceState => _saveGeofenceState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Jenis alert
  GeofenceAlertType _alertType = GeofenceAlertType.enter;
  GeofenceAlertType get alertType => _alertType;

  void setAlertType(GeofenceAlertType type) {
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

  Future<void> loadVehicles() async {
    _loadVehicleState = ResultState.loading;
    notifyListeners();
    try {
      _vehicles = await _repo.getVehicles(searchQuery: '', page: 1);
      _loadVehicleState = _vehicles.isEmpty ? ResultState.noData : ResultState.success;
    } on DioException catch (e) {
      _loadVehicleState = ResultState.error;
      _errorMessage = mapDioErrorToMessage(e);
    } catch (e) {
      _loadVehicleState = ResultState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // Radius sync ke drawManager
  void onRadiusChanged(String value) {
    final r = double.tryParse(value);
    if (r != null) drawManager.updateRadius(r);
  }

  // Simpan vehicle IDs ke SharedPreferences
  Future<void> _saveVehicleIdsForNewGeofence(Set<String> vehicleIds) async {
    if (vehicleIds.isEmpty) return;
    try {
      final allGeofences = await _repo.getGeofenceArea();
      if (allGeofences.isEmpty) return;

      final newGeofence = allGeofences.reduce(
        (a, b) => a.id > b.id ? a : b,
      );

      final prefs = await SharedPreferences.getInstance();
      final key = 'geofence_vehicles_${newGeofence.id}';
      await prefs.setString(key, jsonEncode(vehicleIds.toList()));
    } catch (e) {
      print('[GeofenceCreate] Gagal simpan vehicle IDs lokal: $e');
    }
  }

  // Simpan Geofence
  Future<void> saveGeofence() async {
    _saveGeofenceState = ResultState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final deviceIdsMapped = _selectedIds.map((id) {
        final vehicle = _vehicles.firstWhere(
          (v) => v.id == id,
          orElse: () => Vehicle(id: '', brand: '', plateNumber: '', status: VehicleStatus.down, emei: id, gsm: '', model: '', imageUrl: ''),
        );
        return vehicle.emei.replaceAll(' ', '');
      }).toList();

      final payload = GeofencePayloadBuilder.build(
        mode: drawManager.drawMode,
        name: nameController.text.trim(),
        notif: _alertType == GeofenceAlertType.enter ? 'in' : 'out',
        deviceIds: deviceIdsMapped,
        circleCenter: drawManager.circleCenter,
        radius: drawManager.circleRadius,
        rectStart: drawManager.rectStart,
        rectEnd: drawManager.rectEnd,
        polygonPoints: drawManager.polygonPoints,
      );

      await _repo.createGeofenceRaw(payload: payload);
      await _saveVehicleIdsForNewGeofence(_selectedIds);

      _saveGeofenceState = ResultState.success;
      _bus.emit(DataInvalidationEvent.geofenceChanged);
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _saveGeofenceState = ResultState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _saveGeofenceState = ResultState.error;
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