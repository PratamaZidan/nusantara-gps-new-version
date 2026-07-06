import 'package:shared_preferences/shared_preferences.dart';

// Menyimpan dan membaca health status background service.
class ServiceHealthStore {
  ServiceHealthStore._();
  static final ServiceHealthStore instance = ServiceHealthStore._();

  // Keys
  static const _keyLasAlertCheck = 'health_last_alert_check';
  static const _keyLastGeofenceCheck = 'health_last_geofence_check';
  static const _keyServiceStartedAt = 'health_service_started_at';
  static const _keyAlertCheckCount = 'health_alert_check_count';
  static const _keyGeofenceCheckCount = 'health_geofence_check_count';
  static const _keyLastError = 'health_last_error';

  // Write (dipanggil dari bg isolate)
  Future<void> recordAlertCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    final count = (prefs.getInt(_keyAlertCheckCount) ?? 0) + 1;
    await prefs.setString(_keyLasAlertCheck, now);
    await prefs.setInt(_keyAlertCheckCount, count);
  }

  Future<void> recordGeofenceCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    final count = (prefs.getInt(_keyGeofenceCheckCount) ?? 0) + 1;
    await prefs.setString(_keyLastGeofenceCheck, now);
    await prefs.setInt(_keyGeofenceCheckCount, count);
  }

  Future<void> recordServiceStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServiceStartedAt, DateTime.now().toIso8601String());
    
    // Reset Counter saat service restart
    await prefs.setInt(_keyAlertCheckCount, 0);
    await prefs.setInt(_keyGeofenceCheckCount, 0);
  }

  Future<void> recordError(String context, Object error) async {
    final prefs = await SharedPreferences.getInstance();
    final msg = '[$context] ${DateTime.now().toIso8601String()}: $error';
    await prefs.setString(_keyLastError, msg);
  }

  // Read (dipanggil dari UI thread)
  Future<ServiceHealthSnapshot> getSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    return ServiceHealthSnapshot(
      lastAlertCheck: prefs.getString(_keyLasAlertCheck),
      lastGeofenceCheck: prefs.getString(_keyLastGeofenceCheck),
      serviceStartedAt: prefs.getString(_keyServiceStartedAt),
      alertCheckCount: prefs.getInt(_keyAlertCheckCount) ?? 0,
      geofenceCheckCount: prefs.getInt(_keyGeofenceCheckCount) ?? 0,
      lastError: prefs.getString(_keyLastError),
    );
  }
}

class ServiceHealthSnapshot {
  final String? lastAlertCheck;
  final String? lastGeofenceCheck;
  final String? serviceStartedAt;
  final int alertCheckCount;
  final int geofenceCheckCount;
  final String? lastError;

  ServiceHealthSnapshot({
    required this.lastAlertCheck,
    required this.lastGeofenceCheck,
    required this.serviceStartedAt,
    required this.alertCheckCount,
    required this.geofenceCheckCount,
    required this.lastError,
  });

  // Service dianggap "sehat" kalau geofence check terakhir < 5 menit yang lalu
  bool get isHealthy {
    if (lastGeofenceCheck == null) return false;
    final last = DateTime.tryParse(lastGeofenceCheck!);
    if (last == null) return false;
    return DateTime.now().difference(last) < Duration(minutes: 5);
  }

  String get serviceUptime {
    if (serviceStartedAt == null) return '-';
    final start = DateTime.tryParse(serviceStartedAt!);
    if (start == null) return '-';
    final elapsed = DateTime.now().difference(start);
    if (elapsed.inHours > 0) return '${elapsed.inHours}j ${elapsed.inMinutes.remainder(60)}m';
    return '${elapsed.inMinutes}m ${elapsed.inSeconds.remainder(60)}d';
  }
}