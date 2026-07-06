// Menyimpan status posisi kendaraan pada setiap geofence
enum GeofenceStatus {inside, outside, unknown}

class GeofenceStatusTracker {
  GeofenceStatusTracker._();
  static final GeofenceStatusTracker instance = GeofenceStatusTracker._();

  DateTime Function() now = DateTime.now;

  // Key: deviceId_geofenceId -> status terakhir
  final Map<String, GeofenceStatus> _lastStatus = {};

  // Key: deviceId_geofenceId -> timestamp terakhir perubahan status
  final Map<String, DateTime> _lastChangeTime = {};
  final Map<String, DateTime> _lastSeenTime = {};   // untuk stabil/jitter

  // Cooldown minimum sebelum status berubah lagi
  static const Duration _cooldown = Duration(seconds: 30);

  // Cek status untuk trigger notif
  GeofenceEvent? checkAndUpdate({
    required String deviceId,
    required int geofenceId,
    required String geofenceName,
    required String deviceName,
    required bool isCurrentlyInside,
  }) {
    final key = '${deviceId}_$geofenceId';
    final newStatus = isCurrentlyInside
        ? GeofenceStatus.inside
        : GeofenceStatus.outside;
    final lastStatus = _lastStatus[key] ?? GeofenceStatus.unknown;
    final nowTime = now();

    // Pertama deteksi, simpan jangan trigger notif
    if (lastStatus == GeofenceStatus.unknown) {
      _lastStatus[key] = newStatus;
      _lastChangeTime[key] = nowTime;
      _lastSeenTime[key] = nowTime;
      return null;
    }

    // Status sama -> tidak ada perubahan
    if (lastStatus == newStatus) {
      _lastSeenTime[key] = nowTime;
      return null;
    }

    // Cek cooldown dari perubahan status terakhir
    final lastChange = _lastChangeTime[key];

    if (lastChange != null) {
      final elapsed = now().difference(lastChange);
      if (elapsed < _cooldown) return null;
    }

    // Status berubah dan sudah lewat cooldown -> update & return event
    _lastStatus[key] = newStatus;
    _lastChangeTime[key] = nowTime;
    _lastSeenTime[key] = nowTime;

    return GeofenceEvent(
      deviceId: deviceId,
      deviceName: deviceName,
      geofenceId: geofenceId,
      geofenceName: geofenceName,
      isEntering: isCurrentlyInside, //true = masuk, false = keluar
    );
  }

  // Reset semua status (misal saat app start atau user logout)
  void reset() {
    _lastStatus.clear();
    _lastChangeTime.clear();
    _lastSeenTime.clear();
  }
}

  // Event geofence yang perlu di notifikasi
  class GeofenceEvent {
    final String deviceId;
    final String deviceName;
    final int geofenceId;
    final String geofenceName;
    final bool isEntering; // true = masuk, false = keluar

    GeofenceEvent({
      required this.deviceId,
      required this.deviceName,
      required this.geofenceId,
      required this.geofenceName,
      required this.isEntering,
    });

    String get title => isEntering
        ? 'Kendaraan Masuk Geofence'
        : 'Kendaraan Keluar Geofence';

    String get body =>
        '$deviceName ${isEntering ? 'masuk' : 'keluar'} area ${geofenceName}';
  }