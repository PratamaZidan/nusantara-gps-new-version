import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/date_time_extention.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/data/models/daily_report_model.dart';
import 'package:nusantara_gps/domain/interfaces/i_vehicle_repository.dart';

class TripReportViewModel extends ChangeNotifier {
  final IVehicleRepository _repo;
  TripReportViewModel(this._repo);

  // Tanggal yang dipilih
  DateTime _start = DateTime.now();
  DateTime _end   = DateTime.now();

  // Untuk backward compact dengan screen lama
  String get startDate => _start.toSimpleFormat();
  String get endDate => _end.toSimpleFormat();

  void setRangeDate(DateTimeRange? range) {
    if (range == null) return;
    _start = range.start;
    _end = range.end;
    notifyListeners();
  }

  // Data laporan harian
  List<DailyReportModel> _dailyReports = [];
  List<DailyReportModel> get dailyReports => _dailyReports;

  // Backward compact - screen lama akses tripReports
  List<DailyReportModel> get tripReports => _dailyReports;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ResultState _loadState = ResultState.initial;
  ResultState get loadState => _loadState;

  CancelToken? _cancelToken;

  // Load
  Future<void> loadTripReport(int deviceId) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    _loadState = ResultState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repo.getDailyReport(
        date: _start,
        endDate: _end,
      );

      if (data.isEmpty) {
        _loadState = ResultState.noData;
        _errorMessage = 'Tidak ada data pada tanggal ini';
      } else {
        _dailyReports = (deviceId > 0)
            ? data.where((r) => r.deviceId == deviceId).toList()
            : data;

        if (_dailyReports.isEmpty) {
          _loadState = ResultState.noData;
          _errorMessage = 'Tidak ada data untuk kendaraan ini';
        } else {
          _loadState = ResultState.success;
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _loadState = ResultState.initial;
        notifyListeners();
        return;
      }
      _errorMessage = mapDioErrorToMessage(e);
      _loadState = ResultState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _loadState = ResultState.error;
    } finally {
      notifyListeners();
    }
  }
}