import 'package:nusantara_gps/core/config/app_config.dart';
import 'package:nusantara_gps/core/service/dio_service.dart';
import 'package:nusantara_gps/data/dto/location_iq_dto.dart';

abstract class ILocationIqRemoteDataSource {
  Future<LocationIqDTO> fetchAdddress({
    required double lat,
    required double lng,
  });
}

class LocationIqRemoteDataSourceImpl implements ILocationIqRemoteDataSource {
  final DioService _dioService;

  LocationIqRemoteDataSourceImpl(this._dioService);
  @override
  Future<LocationIqDTO> fetchAdddress({
    required double lat,
    required double lng,
  }) async {
    final dio = _dioService.dio;
    final response = await dio.get(
      'reverse',
      queryParameters: {
        'lat': lat,
        'lon': lng,
        'format': 'json',
        'key': AppConfig.locationIqApiKey,
      },
    );
    return LocationIqDTO.fromJson(response.data as Map<String, dynamic>);
  }
}
