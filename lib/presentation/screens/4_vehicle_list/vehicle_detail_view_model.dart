import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/data/models/detail_vehicle.dart';
import 'package:nusantara_gps/data/models/position.dart';
import 'package:nusantara_gps/domain/interfaces/i_tracking_repository.dart';
import 'package:nusantara_gps/domain/interfaces/i_vehicle_repository.dart';

class VehicleDetailViewModel extends ChangeNotifier {
  final IVehicleRepository _repo;
  final ITrackingRepository _trackingRepo;
  VehicleDetailViewModel(this._repo, this._trackingRepo);

  DetailVehicle? _vehicle;
  DetailVehicle? get vehicle => _vehicle;

  bool _fuelCutSwitch = false;
  bool get fuelCutSwitch => _fuelCutSwitch;

  PositionModel? _position;
  PositionModel? get position => _position;

  ResultState _loadVehicleDetail = ResultState.initial;
  ResultState get loadVehicleDetail => _loadVehicleDetail;

  ResultState _loadPosition = ResultState.initial;
  ResultState get loadPosition => _loadPosition;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> load(String id) async {
    _loadVehicleDetail = ResultState.loading;
    _loadPosition = ResultState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _vehicle = await _repo.getDetailVehicle(id);

      if (_vehicle != null) {
        _loadVehicleDetail = ResultState.success;
        notifyListeners();

        await loadTraccarPosition();
      } else {
        _loadVehicleDetail = ResultState.noData;
        _loadPosition = ResultState.noData;
      }
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _loadVehicleDetail = ResultState.error;
      _loadPosition = ResultState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _loadVehicleDetail = ResultState.error;
      _loadPosition = ResultState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadTraccarPosition() async {
    _loadPosition = ResultState.loading;
    notifyListeners();
    try {
      final data = await _trackingRepo.getPosition(
        deviceId: _vehicle?.emei ?? '0',
      );
      _position = data.isNotEmpty ? data.first : null;
      _loadPosition = _position != null ? ResultState.success : ResultState.noData;
      notifyListeners();
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _loadPosition = ResultState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _loadPosition = ResultState.error;
    } finally {
      notifyListeners();
    }
  }

  void toggleFuelCutSwitch() {
    _fuelCutSwitch = !_fuelCutSwitch;
    notifyListeners();
  }
}
