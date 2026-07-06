import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/utils/date_time_extention.dart';
import 'package:nusantara_gps/data/datasourse/i_vehicle_remote_data_source.dart';
import 'package:nusantara_gps/data/models/detail_vehicle.dart';
import 'package:nusantara_gps/data/models/geofence_model.dart';
import 'package:nusantara_gps/data/models/position.dart';
import 'package:nusantara_gps/data/models/trip_report_model.dart';
import 'package:nusantara_gps/data/models/vehicle_model.dart';
import 'package:nusantara_gps/data/models/daily_report_model.dart';
import 'package:nusantara_gps/domain/interfaces/i_vehicle_repository.dart';
import 'package:nusantara_gps/data/mappers/lacak_detail_vehicle_mapper.dart';
import 'package:nusantara_gps/data/mappers/lacak_geofence_mapper.dart';
import 'package:nusantara_gps/core/utils/geofence_circle_polygon_util.dart';
import 'package:nusantara_gps/core/utils/geofence_wkt_util.dart';

class VehicleRepositoryImpl implements IVehicleRepository {
  final IVehicleRemoteDataSource _remote;

  VehicleRepositoryImpl(this._remote);

  @override
  Future<DetailVehicle> getDetailVehicle(String id) async {
    final json = await _remote.fetchListDevicesRaw();

    final root = (json['root'] is List) ? json['root'] as List : const [];

    final item = root
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .firstWhere(
          (e) =>
              e['id']?.toString() == id ||
              e['uuid']?.toString() == id ||
              e['vehicleid']?.toString() == id ||
              e['deviceid']?.toString() == id,
          orElse: () => <String, dynamic>{},
        );
    if (item.isEmpty) {
      throw Exception('Detail kendaraan dengan id=$id tidak ditemukan');
    }

    return LacakDetailVehicleMapper.fromListDevicesItem(item);
  }

  @override
  Future<List<Vehicle>> getVehicles({
    String searchQuery = '',
    int page = 1,
  }) async {
    try {
      final dto = await _remote.getVehicles(
        searchQuery: searchQuery,
        page: page,
      );
      final vehicles = dto.data?.map((e) => e.toEntity()).toList() ?? [];
      return vehicles;
    } on DioException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<List<PositionModel>> getTripPointReportByDate(
    int deviceId,
    String startDate,
    String endDate,
  ) async {
    try {
      final raw = await _remote.fetchTripPointsRaw(
        deviceId: deviceId, 
        startDate: startDate, 
        endDate: endDate
      );

      final List root = (raw is Map && raw['root'] is List)
        ? raw['root'] as List
        : [];

      return root.whereType<Map>().map((point) {
        final p = Map<String, dynamic>.from(point);
        return PositionModel(
          deviceId: deviceId,
          latitude: _parseDouble(p['lat']),
          longitude: _parseDouble(p['lng']),
          fixTime: _parseTimeFromTitle(p['title']?.toString() ?? ''),
          speed: 0,
          course: 0,
          address: '',
          status: VehicleStatus.on,
          sat: int.tryParse(p['sat']?.toString() ?? '') ?? 0,
          totalDistance: _parseDouble(p['totalDistance']),
          deviceTime: p['deviceTime']?.toString() ?? '',
          serverTimeUTC: _parseDateTime(p['serverTimeUTC']?.toString() ?? ''),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // History perjalanan dari Lacak listlines
  @override
  Future<List<TripReportModel>> getTripHistoryByDate(
    int deviceId,
    DateTime startDate,
    DateTime endDate, {
    CancelToken? cancelToken,
  }) async {
    final from = startDate.toListlinesEarlyDay();
    final to = endDate.toListlinesEndDay();

    try {
      final dto = await _remote.fetchTripReportsByDate(
        deviceId,
        from,
        to,
        cancelToken: cancelToken,
      );
      final data = dto.data?.map((e) => e.toEntity()).toList() ?? [];
      return data;
    } on DioException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<List<DailyReportModel>> getDailyReport({
    required DateTime date,
    DateTime? endDate,
  }) async {
    // Jika endDate diberikan → pakai range; jika tidak → satu hari penuh
    final tgl1 = date.toListlinesEarlyDay(); 
    final tgl2 = (endDate ?? date).toListlinesEndDay();

    final response = await _remote.fetchDailyStats(
      tgl1: tgl1,
      tgl2: tgl2,
    );

    final List root = response['root'] ?? [];
    return root
        .whereType<Map>()
        .map((e) => DailyReportModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<GeofenceModel>> getGeofenceArea() async {
    try {
      final raw = await _remote.fetchGeofenceRaw();
      final geofences = LacakGeofenceMapper.toEntities(raw);
      return geofences;
    } on DioException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> createGeofence({
    required String name,
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  }) async {
    final polygon = GeofenceCirclePolygonUtil.generatePolygon(
      centerLat: centerLat,
      centerLng: centerLng,
      radiusMeters: radiusMeters,
    );

    final areaWkt = GeofenceWktUtil.polygonToWkt(polygon);

    await _remote.createGeofence(
      payload: {
        'name' : name,
        'lat' : centerLat,
        'lng' : centerLng,
        'radius' : radiusMeters,
        'polygon' : areaWkt,
      },
    );
  }

  @override
  Future<void> updateGeofence({
    required int id,
    required String name,
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  }) async {
    final polygon = GeofenceCirclePolygonUtil.generatePolygon(
      centerLat: centerLat,
      centerLng: centerLng,
      radiusMeters: radiusMeters,
    );

    final areaWkt = GeofenceWktUtil.polygonToWkt(polygon);

    await _remote.updateGeofence(
      payload: {
        'id' : id,
        'name' : name,
        'lat' : centerLat,
        'lng' : centerLng,
        'radius' : radiusMeters,
        'polygon' : areaWkt,
      },
    );
  }

  @override
  Future<void> deleteGeofence({
    required int id,
  }) async {
    await _remote.deleteGeofence(id: id);
  }

  @override
  Future<void> createGeofenceRaw({
    required Map<String, dynamic> payload,
  }) async {
    await _remote.createGeofence(payload: payload);
  }

  @override
  Future<GeofenceModel?> getGeofenceById(int id) async {
    final items = await getGeofenceArea();
    try {
      return items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

// Helper parse double
double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

// Helper timestamp
DateTime _parseTimeFromTitle(String title) {
  try {
    final match = RegExp(r'<b>(.*?)<\/b>').firstMatch(title);
    if (match == null) return DateTime.now();
    final dateStr = match.group(1) ?? '';

    final cleaned = dateStr
        .replaceAll(RegExp(r'GMT[+-]\d+'), '')
        .trim();
    return _parseIndonesianDate(cleaned);
  } catch (_) {
    return DateTime.now();
  }
}

DateTime _parseDateTime(String dateTimeStr) {
  if (dateTimeStr.isEmpty) return DateTime.now();
  try {
    return DateTime.parse(dateTimeStr);
  } catch (_) {
    return DateTime.now();
  }
}

DateTime _parseIndonesianDate(String dateStr) {
  const months = {
      'Januari': 1, 'Februari': 2, 'Maret': 3, 'April': 4,
      'Mei': 5, 'Juni': 6, 'Juli': 7, 'Agustus': 8,
      'September': 9, 'Oktober': 10, 'November': 11, 'Desember': 12,
      // English fallback
      'January': 1, 'February': 2, 'March': 3, 'May': 5,
      'June': 6, 'July': 7, 'August': 8, 'October': 10, 'December': 12,
    };

    final parts = dateStr.trim().split(RegExp(r'\s+'));
    if (parts.length < 4) return DateTime.now();

    final day = int.tryParse(parts[0]) ?? 1;
    final month = months[parts[1]] ?? 1;
    final year = int.tryParse(parts[2]) ?? 2024;

    final timeParts = parts[3].split(':');
    final hour   = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
    final second = int.tryParse(timeParts.length > 2 ? timeParts[2] : '0') ?? 0;

    return DateTime(year, month, day, hour, minute, second);
}