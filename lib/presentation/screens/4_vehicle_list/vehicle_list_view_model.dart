import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/data/models/vehicle_model.dart';
import 'package:nusantara_gps/domain/interfaces/i_vehicle_repository.dart';

class VehicleListViewModel extends ChangeNotifier {
  final IVehicleRepository _repo;

  VehicleListViewModel(this._repo);

  final TextEditingController searchQueryController = TextEditingController();

  late final PagingController<int, Vehicle> pagingController =
      PagingController<int, Vehicle>(
    getNextPageKey: (state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) => _repo.getVehicles(
      searchQuery: searchQueryController.text,
      page: pageKey,
    ),
  );

  /// Dipakai saat user klik search / submit keyword
  void refresh() {
    pagingController.refresh();
  }

  @override
  void dispose() {
    searchQueryController.dispose();
    pagingController.dispose();
    super.dispose();
  }

  List<Vehicle> _items = [];
  List<Vehicle> get items => _items;

  ResultState _loadVehicleState = ResultState.initial;
  ResultState get loadVehicleState => _loadVehicleState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _statusCode;
  int? get statusCode => _statusCode;

  Future<void> loadVehicles() async {
    _loadVehicleState = ResultState.loading;
    notifyListeners();
    try {
      final data = await _repo.getVehicles(
        searchQuery: searchQueryController.text,
      );
      if (data.isEmpty) {
        _loadVehicleState = ResultState.noData;
      } else {
        // ✅ PERBAIKAN: DEDUPLIKASI EXTRA DI LEVEL UI SEBAGAI SAFETY NET
        final Set<String> seenIds = {};
        final dedupedData = <Vehicle>[];
        
        for (final vehicle in data) {
          if (!seenIds.contains(vehicle.id)) {
            seenIds.add(vehicle.id);
            dedupedData.add(vehicle);
          }
        }
        
        _items = dedupedData;
        _loadVehicleState = ResultState.success;
      }
    } on DioException catch (e) {
      _statusCode = e.response?.statusCode;
      _errorMessage = mapDioErrorToMessage(e);
      _loadVehicleState = ResultState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _loadVehicleState = ResultState.error;
    } finally {
      notifyListeners();
    }
  }
}