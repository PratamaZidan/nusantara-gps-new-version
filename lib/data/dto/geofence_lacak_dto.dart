class GeofenceLacakDto {
  final int id;
  final String name;
  final String geotype;
  final double lat1;
  final double lng1;
  final double point3;
  final double point4;
  final String polygonRaw;
  final String? inout;
  final String? notification;
  final List<String> deviceIds;

  GeofenceLacakDto({
    required this.id,
    required this.name,
    required this.geotype,
    required this.lat1,
    required this.lng1,
    required this.point3,
    required this.point4,
    required this.polygonRaw,
    this.inout,
    this.notification,
    this.deviceIds = const [],
  });

  double get radiusMeters => point3;
  double get lat2 => point3;
  double get lng2 => point4;

  factory GeofenceLacakDto.fromJson(Map<String, dynamic> json) {
    // LOG: tampilkan semua field dari API untuk satu item pertama
    print('[GEOFENCE_DTO] raw keys: ${json.keys.toList()}');
    print('[GEOFENCE_DTO] inout="${json['inout']}" notifikasi="${json['notifikasi']}" device_ids="${json['device_ids']}" devices="${json['devices']}"');

    return GeofenceLacakDto(
      id:           _parseInt(json['id']),
      name:         (json['nama'] ?? json['name'] ?? 'Unnamed Geofence').toString(),
      geotype:      (json['geo_type'] ?? '').toString(),
      lat1:         _parseDouble(json['geo_point1']),
      lng1:         _parseDouble(json['geo_point2']),
      point3:       _parseDouble(json['geo_point3']), 
      point4:       _parseDouble(json['geo_point4']),
      polygonRaw:   (json['polygon'] ?? '').toString(),
      inout:        json['inout']?.toString(),
      notification: json['notifikasi']?.toString(),
      deviceIds:    _parseDeviceIds(json),
    );
  }

  static List<String> _parseDeviceIds(Map<String, dynamic> json) {
    final value = json['device_ids'] ?? json['devices'] ?? json['device_id'];
    if (value == null) return [];
    if (value is List) {
      return value.map((e) {
        if (e is Map) {
          return (e['id'] ?? e['device_id'] ?? '').toString();
        }
        return e.toString();
      }).where((id) => id.isNotEmpty).toList();
    }
    if (value is String) {
      if (value.trim().isEmpty) return [];
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (value is int) {
      return [value.toString()];
    }
    return [];
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}