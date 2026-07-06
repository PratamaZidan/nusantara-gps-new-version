import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:nusantara_gps/core/service/dio_service.dart';
import 'package:nusantara_gps/data/models/alert_model.dart';
import 'package:nusantara_gps/domain/interfaces/i_alert_repository.dart';

class AlertRepositoryImpl implements IAlertRepository {
  final DioService _dioService;

  AlertRepositoryImpl(this._dioService);

  @override
  Future<List<AlertModel>> getAlerts({int page = 1}) async {
    final response = await _dioService.dio.get(
      'hrpc.php',
      queryParameters: {
        'act': 'listalert',
        'page': page,
      },
      options: Options(responseType: ResponseType.plain),
    );

    final raw = response.data is String
        ? jsonDecode(response.data)
        : response.data;

    final List root = raw['root'] ?? [];
    return root
        .whereType<Map>()
        .map((e) => AlertModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}