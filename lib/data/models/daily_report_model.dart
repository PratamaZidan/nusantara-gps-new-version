class DailyReportModel {
  final String device;
  final int deviceId;
  final String date;

  // Posisi awal & akhir
  final double firstLat;
  final double firstLng;
  final double lastLat;
  final double lastLng;

  // Waktu
  final String firstTs;
  final String lastTs;

  // Alamat
  final String? firstAddr;
  final String? lastAddr;

  // Statistik perjalanan
  final double distance;
  final String run;
  final String stop;
  final double speedAvg;
  final double speedMax;
  final int speedNum;

  // Odometer
  final double firstMileage;
  final double lastMileage;

  DailyReportModel ({
    required this.device,
    required this.deviceId,
    required this.date,
    required this.firstLat,
    required this.firstLng,
    required this.lastLat,
    required this.lastLng,
    required this.firstTs,
    required this.lastTs,
    this.firstAddr,
    this.lastAddr,
    required this.distance,
    required this.run,
    required this.stop,
    required this.speedAvg,
    required this.speedMax,
    required this.speedNum,
    required this.firstMileage,
    required this.lastMileage,
  });

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    final speed = _parseDouble(json['speed']);
    final speedNum = _parseInt(json['speednum']);
    final speedAvg = _parseDouble(json['speedavg']);
    final speedMax = speedNum > 0 ? speed / speedNum : 0.0;

    return DailyReportModel(
      device: json['device']?.toString() ?? '',
      deviceId: _parseInt(json['deviceid']),
      date: json['date']?.toString() ?? '',
      firstLat: _parseDouble(json['firstlat']),
      firstLng: _parseDouble(json['firstlng']),
      lastLat: _parseDouble(json['lastlat']),
      lastLng: _parseDouble(json['lastlng']),
      firstTs: json['firstts']?.toString() ?? '',
      lastTs: json['lastts']?.toString() ?? '',
      firstAddr: _parseAddr(json['firstaddr']),
      lastAddr: _parseAddr(json['lastaddr']),
      distance: _parseDouble(json['distance']),
      run:  _sanitizeDuration(json['run']?.toString()),
      stop: _sanitizeDuration(json['stop']?.toString()),
      speedAvg: speedAvg,
      speedMax: speedMax,
      speedNum: speedNum,
      firstMileage: _parseDouble(json['firstmileage']),
      lastMileage: _parseDouble(json['lastmileage']),
    );
  }

  // Computed Getters
  double get distanceKm => distance / 1000;
  double get firstOdometerKm => firstMileage / 1000;
  double get lastOdometerKm => lastMileage / 1000;
  bool get hasTrip => distance > 0 && run != '00:00:00';

  // Helpers
  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  // API kadang kirim false (bool) bukan null untuk alamat
  static String? _parseAddr(dynamic v) {
    if (v == null || v == false || v.toString().isEmpty) return null;
    return v.toString();
  }

  // Sanitasi durasi dari API format "HH:MM:SS".
  static String _sanitizeDuration(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw =='-') return '00:00:00';

    final parts = raw.trim().split(':');
    if (parts.length != 3) return '00:00:00';

    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final s = int.tryParse(parts[2]);

    // Jika salah satu bagian ga isa diparse atau negatif = reset
    if (h == null || m == null || s == null) return '00:00:00';
    if (h < 0 || m < 0 || s < 0) return '00:00:00';

    // Format ulang dengan zero-padding supaya konsisten
    return '${h.toString().padLeft(2, '0')}:'
            '${m.toString().padLeft(2, '0')}:' 
            '${s.toString().padLeft(2, '0')}';
  }
}