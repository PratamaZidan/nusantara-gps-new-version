import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/service/geofence_event_store.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/data/models/alert_model.dart';
import 'package:nusantara_gps/domain/interfaces/i_alert_repository.dart';

class AlertViewModel extends ChangeNotifier {
  final IAlertRepository _repo;

  AlertViewModel(this._repo);

  ResultState _state = ResultState.initial;
  ResultState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Alert hardware dari API
  List<AlertModel> _alerts = [];
  List<AlertModel> get alerts => _alerts;

  // Alert geofence dari local Hive
  List<GeofenceEventModel> _geofenceEvents = [];
  List<GeofenceEventModel> get geofenceEvents => _geofenceEvents;

  // Untuk infinite scroll / loadmore
  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMOre => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  // Load pertama kali
  Future<void> loadAlerts() async {
    _state = ResultState.loading;
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();

    // Always load geofence events dari local
    _geofenceEvents = GeofenceEventStore().getAll();

    try {
      final data = await _repo.getAlerts(page : 1);
      _alerts = data;
      _hasMore = data.length >= 10; // Asumsi page size 10
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      final hasAny = _alerts.isNotEmpty || _geofenceEvents.isNotEmpty;
      _state = _errorMessage != null && !hasAny
          ? ResultState.error
          : hasAny
              ? ResultState.success
              : ResultState.noData;
      notifyListeners();
    }
  }

  // Refresh (pull to refresh)
  Future<void> refresh() async => await loadAlerts();

  // Load more (scroll ke bawah)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final data = await _repo.getAlerts(page: _currentPage);

      if (data.isEmpty) {
        _hasMore = false;
      } else {
        _alerts = [..._alerts, ...data];
        _hasMore = data.length >= 10; // Asumsi page size 10
      }
    } catch (_) {
      _currentPage--; // Rollback jika gagal
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> clearGeofenceEvents() async {
    await GeofenceEventStore().clearAll();
    _geofenceEvents = [];
    final hasAny = _alerts.isNotEmpty;
    _state = hasAny ? ResultState.success : ResultState.noData;
    notifyListeners();
  }
}