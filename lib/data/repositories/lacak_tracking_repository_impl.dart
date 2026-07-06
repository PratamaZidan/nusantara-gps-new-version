import 'package:dio/dio.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/data/datasourse/i_lacak_tracking_remote_data_source.dart';
import 'package:nusantara_gps/data/datasourse/i_location_iq_remote_data_source.dart';
import 'package:nusantara_gps/data/mappers/lacak_position_mapper.dart';
import 'package:nusantara_gps/data/models/device.dart';
import 'package:nusantara_gps/data/models/position.dart';
import 'package:nusantara_gps/domain/interfaces/i_tracking_repository.dart';

class LacakTrackingRepositoryImpl implements ITrackingRepository {
  final ILacakTrackingRemoteDataSource _remote;
  final ILocationIqRemoteDataSource _locationIqRemoteDataSource;

  LacakTrackingRepositoryImpl(this._remote, this._locationIqRemoteDataSource);

  @override
  Future<List<Device>> getTrackedDevices() async {
    try {
      final json = await _remote.fetchListDevices();
      final List root = (json['root'] is List) ? json['root'] as List : const [];

      return root.whereType<Map>().map((m) {
        final deviceName = (m['device'] ?? '').toString();
        final deviceIdRaw = (m['deviceid'] ?? '').toString();
        final imei = deviceIdRaw.replaceAll(' ', '');
        final imeiInt = int.tryParse(imei) ?? 0;
        final active = (m['active']?.toString() == '1');

        return Device(
          id: imeiInt,
          uniqueId: imei,
          name: deviceName,
          model: deviceName,
          phone: (m['msisdn'] ?? '').toString(),
          status: active ? VehicleStatus.on : VehicleStatus.off,
          positionId: null,
          lastUpdate: DateTime.now(),
          long: 0,
          lat: 0,
          speed: 0,
          direction: 0,
          battery: 0,
        );
      }).toList();
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<List<PositionModel>> getPosition({String? deviceId = ''}) async {
    try {
      final now = DateTime.now();

      // Fetch sumber
      final results = await Future.wait([
        _remote.fetchListDevices(),
        _remote.fetchRealtime(ids: '', kode: '', catid: 0),
      ]);

      final devicesJson = results[0];
      final realtimeJson = results[1];

      final List devRoot = (devicesJson['root'] is List) ? devicesJson['root'] as List : [];
      final List realRoot = (realtimeJson['root'] is List) ? realtimeJson['root'] as List : [];

      // parse listdevices posisi fallback down
      final Map<int, PositionModel> fallbackPositions = {};
      
      for (final raw in devRoot.whereType<Map>()) {
        final m = Map<String, dynamic>.from(raw);
        final imei = (m['deviceid'] ?? '').toString().replaceAll(' ', '');
        final imeiInt = int.tryParse(imei) ?? 0;
        if (imeiInt == 0) continue;

        final lat = double.tryParse((m['latitude'] ?? '').toString()) ?? 0.0;
        final lng = double.tryParse((m['longitude'] ?? '').toString()) ?? 0.0;

        // Device yang belum pernah terdeteksi = skip
        if (lat == 0.0 && lng == 0.0) continue;

        final course = double.tryParse((m['angle'] ?? '0').toString()) ?? 0.0;
        final speed = double.tryParse((m['speed'] ?? '0').toString()) ?? 0.0;

        // Last Update Time
        final serverTime = _firstNonEmpty([
          m['lastpos']?.toString(),
          m['receivetime']?.toString(),
          m['servertime']?.toString(),
        ]);

        fallbackPositions[imeiInt] = PositionModel(
          deviceId: imeiInt,
          latitude: lat,
          longitude: lng,
          course: course,
          sat: 0,
          address: '',
          status: VehicleStatus.down,
          speed: speed,
          totalDistance: 0,
          deviceTime: serverTime ?? '',
          fixTime: _parseLocalTime(serverTime) ?? now,
          serverTimeUTC: _parseUtcTime(serverTime) ?? now.toUtc(),
        );
      }

      // Parse posisi realtime
      final Map<int, PositionModel> realtimePositions = {};

      for (final raw in realRoot.whereType<Map>()) {
        final pos = LacakPositionMapper.fromListKejadianItem(
          Map<String, dynamic>.from(raw),
          now: now,
          downThresholdMinutes: 30,
          standByThresholdMinutes: 10,
          );

          // lat/lng 0 artinya tidak valid
          if (pos.latitude == 0.0 && pos.longitude == 0.0) continue;

          realtimePositions[pos.deviceId] = pos;
      }

      // Merge realtime override fallback
      final merged = <int,PositionModel>{
        ...fallbackPositions,
        ...realtimePositions,
      };

      // Filter per deviceId jika diminta
      return merged.values
          .where((p) => 
              deviceId == null ||
              deviceId.isEmpty ||
              p.deviceId.toString() == deviceId)
          .toList();
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<String> getAddress({required double lat, required double lng}) async {
    final dto = await _locationIqRemoteDataSource.fetchAdddress(lat: lat, lng: lng);
    return dto.displayName ?? 'unknown address';
  }

  @override
  Future<Device> getDeviceById({required int id}) {
    throw UnimplementedError();
  }

  // Helpers
  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  // Parse waktu server ke local time
  DateTime? _parseLocalTime(String? value) {
    final utc = _parseUtcTime(value);
    return utc?.toLocal();
  }

  // Parse waktu server ke UTC
  DateTime? _parseUtcTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().replaceAll(' ', 'T');
    final hasTimezone = RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(normalized);
    final safeValue = hasTimezone ? normalized : '{$normalized}Z';
    return DateTime.tryParse(safeValue)?.toUtc();
  }
}