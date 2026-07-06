import 'package:dio/dio.dart';
import 'package:nusantara_gps/data/models/detail_vehicle.dart';
import 'package:nusantara_gps/data/models/geofence_model.dart';
import 'package:nusantara_gps/data/models/position.dart';
import 'package:nusantara_gps/data/models/trip_report_model.dart';
import 'package:nusantara_gps/data/models/vehicle_model.dart';
import 'package:nusantara_gps/data/models/daily_report_model.dart';

abstract class IVehicleRepository {
  Future<List<Vehicle>> getVehicles({String searchQuery, int page});
  Future<DetailVehicle> getDetailVehicle(String uuid);
  Future<List<PositionModel>> getTripPointReportByDate(
    int deviceId,
    String startDate,
    String endDate,
  );
  Future<List<TripReportModel>> getTripHistoryByDate(
    int deviceId,
    DateTime startDate,
    DateTime endDate, {
    CancelToken? cancelToken,
  });

  Future<List<DailyReportModel>> getDailyReport({
    required DateTime date,
    DateTime? endDate,
  });

  Future<List<GeofenceModel>> getGeofenceArea();

  Future<void> createGeofence({
    required String name,
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  });

  Future<void> updateGeofence({
    required int id,
    required String name,
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  });

  Future<void> deleteGeofence({required int id,});

  Future<void> createGeofenceRaw({
    required Map<String, dynamic> payload,
  });

  Future<GeofenceModel?> getGeofenceById(int id);
}
