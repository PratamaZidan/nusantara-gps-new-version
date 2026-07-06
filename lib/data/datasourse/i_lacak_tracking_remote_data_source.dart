import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:nusantara_gps/core/service/dio_service.dart';

abstract class ILacakTrackingRemoteDataSource {
  Future<Map<String, dynamic>> fetchListDevices();
  Future<Map<String, dynamic>> fetchRealtime({
    String ids,
    String kode,
    int catid,
  });
}

class LacakTrackingRemoteDataSourceImpl implements ILacakTrackingRemoteDataSource {
  final DioService _dioService;
  LacakTrackingRemoteDataSourceImpl(this._dioService);

  Map<String, dynamic> _ensureMap(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    }
    throw const FormatException('Response bukan JSON Map');
  }

  @override
  Future<Map<String, dynamic>> fetchListDevices() async {
    final dio = _dioService.dio;
    final res = await dio.get(
      'hrpc.php',
      queryParameters: const {'act': 'listdevices'},
      options: Options(
        responseType: ResponseType.plain, // paksa plain biar aman (server text/javascript)
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );
    return _ensureMap(res.data);
  }

  @override
  Future<Map<String, dynamic>> fetchRealtime({
    String ids = '',
    String kode = '',
    int catid = 0,
  }) async {
    final dio = _dioService.dio;
    final res = await dio.get(
      'hrpc.php',
      queryParameters: {
        'act': 'listkejadian',
        'ids': ids,
        'kode': kode,
        'catid': catid,
      },
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );
    return _ensureMap(res.data);
  }
}