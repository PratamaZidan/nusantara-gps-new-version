import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/service/dio_service.dart';
import 'package:nusantara_gps/core/service/storage/i_key_value_storage.dart';
import 'package:nusantara_gps/data/dto/detail_vehicle_dto.dart';
import 'package:nusantara_gps/data/dto/trip_report_dto.dart';
import 'package:nusantara_gps/data/dto/vehicle_dto.dart';
import 'package:nusantara_gps/data/dto/geofence_lacak_dto.dart';
import 'package:nusantara_gps/data/mappers/lacak_vehicle_mapper.dart';

abstract class IVehicleRemoteDataSource {
  Future<VehicleDto> getVehicles({
    required String searchQuery,
    required int page,
  });

  Future<Map<String, dynamic>> fetchListDevicesRaw();
  Future<Map<String, dynamic>> fetchGeofenceRaw();

  Future<DetailVehicleDto> getDetailVehicle(String uuid);

  Future<TripReportDTO> fetchTripReportsByDate(
    int deviceId,
    String startDate,
    String endDate, {
    CancelToken? cancelToken,
  });

  Future<Map<String, dynamic>> fetchDailyStats({
    required String tgl1,
    required String tgl2,
  });

  Future<dynamic> fetchTripPointsRaw({
    required int deviceId,
    required String startDate,
    required String endDate,
  });

  Future<void> createGeofence({
    required Map<String, dynamic> payload,
  });

  Future<void> updateGeofence({
    required Map<String, dynamic> payload,
  });

  Future<void> deleteGeofence({
    required int id,
  });
}

class VehicleRemoteDataSourceImpl implements IVehicleRemoteDataSource {
  final DioService _dioService;

  // ignore: unused_field
  final IKeyValueStorage _storage;

  VehicleRemoteDataSourceImpl(this._dioService, this._storage);

  @override
  Future<VehicleDto> getVehicles({
    required String searchQuery,
    required int page,
  }) async {
    final dio = _dioService.dio;

    final response = await dio.get(
      'hrpc.php',
      queryParameters: const {'act': 'listdevices'},
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );

    return LacakVehicleMapper.listDevicesToVehicleDto(
      response.data,
      searchQuery: searchQuery,
      page: page,
    );
  }

  @override
  Future<DetailVehicleDto> getDetailVehicle(String uuid) async {
    throw UnimplementedError(
      'Detail vehicle belum diimplement untuk API Lacak. Biasanya ambil dari listdevices lalu filter.',
    );
  }

  @override
  Future<TripReportDTO> fetchTripReportsByDate(
    int deviceId,
    String startDate,
    String endDate, {
    CancelToken? cancelToken,
  }) async {
    final dio = _dioService.dio;
    final response = await dio.get(
      'hrpc.php',
      queryParameters: {
        'act': 'listlines',
        'tgl1': startDate,
        'tgl2': endDate,
        'devid': deviceId,
        'last': 0,
      },
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );

    if (response.data is Map<String, dynamic>) {
      return TripReportDTO.fromJson(response.data as Map<String, dynamic>);
    }
    if (response.data is List) {
      return TripReportDTO.fromJson({'data': response.data});
    }
    return TripReportDTO.fromJson({'data': []});
  }


  @override
  Future<Map<String, dynamic>> fetchListDevicesRaw() async {
    final dio = _dioService.dio;

    final response = await dio.get(
      'hrpc.php',
      queryParameters: const {'act': 'listdevices'},
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    if (response.data is String) {
      final decoded = jsonDecode(response.data);
      return Map<String, dynamic>.from(decoded as Map);
    }

    throw const FormatException('Response lisdevices bukan JSON object');
  }

  @override
  Future<Map<String, dynamic>> fetchGeofenceRaw() async {
    final dio = _dioService.dio;

    final Response = await dio.get(
      'hrpc.php',
      queryParameters: const {'act': 'listgeofence'},
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );

    if (Response.data is Map<String, dynamic>) {
      return Response.data as Map<String, dynamic>;
    }

    if (Response.data is String) {
      final decoded = jsonDecode(Response.data);
      return Map<String, dynamic>.from(decoded as Map);
    }

    throw const FormatException('Response listgeofences bukan JSON object');
  }

  @override
  Future<void> createGeofence({
    required Map<String, dynamic> payload,
  }) async {
    final dio = _dioService.dio;

    final response = await dio.post(
      'rpc.php',
      queryParameters: {
        'act': 'savegeofence', 
      },
      data: payload, 
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.json,
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );

    _validateGeofenceActionResponse(
      response.data,
      successMessage: 'Geofence berhasil dibuat',
      failureMessage: 'Gagal membuat geofence',
    );
  }

  @override
  Future<void> updateGeofence({
    required Map<String,dynamic> payload,
  }) async {
    final dio = _dioService.dio;

    final response = await dio.put(
      'rpc.php',
      queryParameters: {
        'act': 'savegeofence',
      },
      data: payload,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.json,
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );

    _validateGeofenceActionResponse(response.data, 
        successMessage: 'Geofence berhasil diperbarui',
        failureMessage: 'Gagal memperbarui geofence');
  }

  @override
  Future<void> deleteGeofence({required int id}) async {
    final dio = _dioService.dio;

    final response = await dio.get(
      'rpc.php',
      queryParameters: {
        'act': 'delgeofence',
        'id': id,
      },
    );

    if (response.data == null || response.data.toString().isEmpty) {
      return;
    }

    _validateGeofenceActionResponse(
      response.data,
      successMessage: 'Geofence berhasil dihapus',
      failureMessage: 'Gagal menghapus geofence',
    );
  }

  @override
  Future<dynamic> fetchTripPointsRaw({
    required int deviceId,
    required String startDate,
    required String endDate,
  }) async {
    final dio = _dioService.dio;

    final response = await dio.get(
      'hrpc.php',
      queryParameters: {
        'act': 'listlines',
        'tgl1': startDate, 
        'tgl2': endDate,
        'devid': deviceId,
        'last': 0,
      },
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (c) =>  c != null && c >= 200 && c < 400,
      ),
    );

    // Response sudah berformat Map dg key 
    if (response.data is Map) return response.data;
    if(response.data is String) {
      return jsonDecode(response.data as String);
    }
    return {'root': []};
  }

  @override
  Future<Map<String, dynamic>> fetchDailyStats({
    required String tgl1,
    required String tgl2,
  }) async {
    final dio = _dioService.dio;

    final response = await dio.get(
      'rpc.php',                         
      queryParameters: {
        'act' : 'dailystats',
        'tgl1' : tgl1,                   
        'tgl2' : tgl2,                  
      },
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );

    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    if (response.data is String) {
      final decoded = jsonDecode(response.data as String);
      return Map<String, dynamic>.from(decoded as Map);
    }

    return {'root': []};
  }
}

void _validateGeofenceActionResponse(dynamic data, {String? successMessage, String? failureMessage}) {
  final fallbackMessage = failureMessage ?? 'Operation failed';
  
  if (data is Map<String, dynamic>) {
    final success =
        data['success'] == true ||
        data['status'] == true ||
        data['ok'] == 1 ||
        data['code'] == 200 ||
        data['result'] == 'success';

    if (!success) {
      throw Exception((data['message'] ?? data ['msg'] ?? fallbackMessage).toString());
    }
    return;
  }

  if (data is String) {
    final text = data.toLowerCase();
    if (text.contains('success') || text.contains('berhasil')) return;
  }

  throw Exception(fallbackMessage);
}