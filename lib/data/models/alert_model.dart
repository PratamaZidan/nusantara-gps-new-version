class AlertModel {
  final String id;
  final String deviceId;
  final String deviceName;
  final String? geofenceId;
  final String? geofenceName;
  final String message;
  final String timestamp;

  const AlertModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    this.geofenceId,
    this.geofenceName,
    required this.message,
    required this.timestamp,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString() ?? '',
      deviceId: json['deviceid']?.toString() ?? '',
      deviceName: json['devicename']?.toString() ?? '',
      geofenceId: json['geofenceid']?.toString(),
      geofenceName: json['geofencename']?.toString(),
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  // Konversi ke Map untuk disimpan ke SharedPreferences
  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceid': deviceId,
    'devicename': deviceName,
    'geofenceid': geofenceId,
    'geofencename': geofenceName,
    'message': message,
    'timestamp': timestamp,
  };

  // Label singkat jenis alert berdasarkan message
  String get alertType {
    final msg = message.toUpperCase();
    if (msg.contains('SHOCK')) return 'Benturan';
    if (msg.contains('POWER_CUT')) return 'Sambungan Terputus';
    if (msg.contains('GEOFENCE')) return 'Geofence';
    if (msg.contains('SOS')) return 'SOS';
    if (msg.contains('OVERSPEED')) return 'Kecepatan Berlebih';
    return 'Alert';
  }

  // Pesan yang sudah diformat untuk ditampilkan ke user
  String get formattedMessage {
    final msg = message.toUpperCase();
    if (msg.contains('SHOCK')) return 'Kendaraan terdeteksi benturan/guncangan';
    if (msg.contains('POWER_CUT')) return 'Koneksi GPS Terputus';
    if (msg.contains('SOS')) return 'Tombol SOS ditekan';
    if (msg.contains('OVERSPEED')) return 'Kecepatan berlebih terdeteksi';
    if (msg.contains('GEOFENCE')) return 'Pelanggaran area geofence';
    return message;
  }
}
