import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/data/models/position.dart';
import 'package:nusantara_gps/core/utils/distance_util.dart';

class LacakPositionMapper {
  /// Parse waktu server.
  /// Jika string tidak punya timezone, anggap UTC.
  static DateTime? _parseServerTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final normalized = value.trim().replaceFirst(' ', 'T');
    final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(normalized);
    final safeValue = hasTimezone ? normalized : '${normalized}Z';

    final parsed = DateTime.tryParse(safeValue);
    return parsed?.toUtc();
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value == 1;

    final str = value.toString().trim().toLowerCase();
    return str == '1' || str == 'true' || str == 'on';
  }

  /// Prioritas ignition:
  /// 1. marker.ignition
  /// 2. root ignition
  /// 3. marker.engine
  /// 4. root engine
  static bool _extractIgnition(Map<String, dynamic> m) {
    final marker = m['marker'];

    if (marker is Map && marker['ignition'] != null) {
      return _toBool(marker['ignition']);
    }
    if (m['ignition'] != null) {
      return _toBool(m['ignition']);
    }
    if (marker is Map && marker['engine'] != null) {
      return _toBool(marker['engine']);
    }
    return _toBool(m['engine']);
  }

  /// Ambil icon backend dari root / marker
  static String _extractIcon(Map<String, dynamic> m) {
    final marker = m['marker'];

    final rootIcon = (m['icon'] ?? '').toString().trim();
    if (rootIcon.isNotEmpty) return rootIcon.toLowerCase();

    if (marker is Map && marker['icon'] != null) {
      return marker['icon'].toString().trim().toLowerCase();
    }

    return '';
  }

  /// Mapping icon backend ke status.
  static VehicleStatus? _statusFromBackendIcon(String icon) {
    if (icon.isEmpty) return null;

    if (icon.contains('_on')) return VehicleStatus.on;
    if (icon.contains('_off')) return VehicleStatus.off;
    if (icon.contains('standby')) return VehicleStatus.standby;

    if (icon.contains('down') ||
        icon.contains('lost') ||
        icon.contains('nodata') ||
        icon.contains('offline')) {
      return VehicleStatus.down;
    }

    return null;
  }

  /// Fallback logic status:
  /// - >30 menit  => down
  /// - >10 menit  => standby
  /// - <=10 menit => on/off tergantung ignition
  static VehicleStatus _statusFromTimeAndIgnition({
    required DateTime now,
    String? serverTime,
    required bool ignition,
    int standByThresholdMinutes = 10,
    int downThresholdMinutes = 30,
  }) {
    if (serverTime == null || serverTime.trim().isEmpty) {
      return VehicleStatus.down;
    }

    final lastServerTimeUtc = _parseServerTime(serverTime);
    if (lastServerTimeUtc == null) {
      return VehicleStatus.down;
    }

    final nowUtc = now.toUtc();
    final diffMinutes = nowUtc.difference(lastServerTimeUtc).inMinutes;
    final safeDiffMinutes = diffMinutes < 0 ? 0 : diffMinutes;

    if (safeDiffMinutes > downThresholdMinutes) {
      return VehicleStatus.down;
    }

    if (safeDiffMinutes > standByThresholdMinutes) {
      return VehicleStatus.standby;
    }

    return ignition ? VehicleStatus.on : VehicleStatus.off;
  }

  static int _voltageLevelToPercent(int level, {int maxLevel = 6}) {
    if (level <= 0) return 0;
    if (level >= maxLevel) return 100;
    return ((level / maxLevel) * 100).round();
  }

  static PositionModel fromListKejadianItem(
    Map<String, dynamic> m, {
    required DateTime now,
    int standByThresholdMinutes = 10,
    int downThresholdMinutes = 30,
  }) {
    final deviceIdStr = (m['deviceid'] ?? '').toString().replaceAll(' ', '');
    final deviceId = int.tryParse(deviceIdStr) ?? 0;

    final lat = (m['lat'] is num)
        ? (m['lat'] as num).toDouble()
        : double.tryParse('${m['lat']}') ?? 0.0;

    final lng = (m['lng'] is num)
        ? (m['lng'] as num).toDouble()
        : double.tryParse('${m['lng']}') ?? 0.0;

    final speed =
        double.tryParse((m['speed'] ?? '0').toString().replaceAll(',', '')) ??
            0.0;

    final course =
        double.tryParse((m['angle'] ?? '0').toString().replaceAll(',', '')) ??
            0.0;

    final sat = int.tryParse((m['signal'] ?? '0').toString()) ?? 0;
    final address = (m['address'] ?? '').toString();

    final totalDistance = normalizeMileageToKm(m['mileage']);

    final voltageLevel = int.tryParse((m['voltage'] ?? '0').toString()) ?? 0;
    final batteryPercent = _voltageLevelToPercent(voltageLevel);

    /// Prioritas waktu:
    /// 1. serverTime
    /// 2. timestamp1
    /// 3. marker.timestamp
    final serverTime =
        (m['serverTime'] ?? m['timestamp1'] ?? m['marker']?['timestamp'] ?? '')
            .toString();

    final ignition = _extractIgnition(m);
    final icon = _extractIcon(m);
    final parsedTimeUtc = _parseServerTime(serverTime) ?? now.toUtc();

    final backendStatus = _statusFromBackendIcon(icon);

    final status = backendStatus ??
        _statusFromTimeAndIgnition(
          now: now,
          serverTime: serverTime,
          ignition: ignition,
          standByThresholdMinutes: standByThresholdMinutes,
          downThresholdMinutes: downThresholdMinutes,
        );

    return PositionModel(
      deviceId: deviceId,
      latitude: lat,
      longitude: lng,
      course: course,
      sat: sat,
      address: address,
      status: status,
      speed: speed,
      totalDistance: totalDistance,
      batteryPercent: batteryPercent,
      voltageLevel: voltageLevel,
      deviceTime: serverTime,
      fixTime: parsedTimeUtc.toLocal(),
      serverTimeUTC: parsedTimeUtc,
    );
  }
}