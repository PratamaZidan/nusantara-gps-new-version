import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofenceModel {
  final int id;
  final String name;
  final List<LatLng> polygon;
  final String? description;
  final String? areaRaw;

  final double? centerLat;
  final double? centerLng;
  final double? radiusMeters;
  final String geoType;
  final String inout;
  final List<String> deviceIds;

  GeofenceModel({
    required this.id,
    required this.name,
    required this.polygon,
    this.description,
    this.areaRaw,
    this.centerLat,
    this.centerLng,
    this.radiusMeters,
    this.geoType = '0', // Default polygon jika tidak ada
    this.inout = '1', // Default inout jika tidak ada
    this.deviceIds = const [],
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    return GeofenceModel(
      id: int.parse(json['id'].toString()), 
      name: json['nama'] ?? '', 
      polygon: _parsePolygon(json['polygon']),
      centerLat: double.tryParse(json['geo_point1'].toString()),
      centerLng: double.tryParse(json['geo_point2'].toString()),
      radiusMeters: double.tryParse(json['geo_point3'].toString()),
      geoType: json['geo_type'] ?? '0',
      inout: json['inout']?.toString() ?? '1',
      deviceIds: _parseDeviceIds(json),
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

  static List<LatLng> _parsePolygon(String? polygon) {
    if (polygon == null || polygon.isEmpty || polygon == '0') return [];

    try {
      return polygon.split('|').map((point) {
        final parts = point.split(',');
        return LatLng(
          double.parse(parts[0]),
          double.parse(parts[1]),
        );
      }).toList();
    } catch (e) {
      print("Error Parse Polygon $e");
      return [];
    }
  }

  // Identifikasi bentuk geofence berdasarkan geoType
  bool get isCircle => geoType == '1';
  bool get isRectangle => geoType == '2';
  bool get isPolygon => geoType == '0' || geoType == '3';
}