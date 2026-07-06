import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/domain/entities/geofence_draw_mode.dart';

class GeofencePayloadBuilder {
  GeofencePayloadBuilder._();

  static const String _typeCircle    = '1';
  static const String _typeRectangle = '2';
  static const String _typePolygon   = '0';

  // CREATE
  static Map<String, dynamic> build({
    required GeofenceDrawMode mode,
    required String name,
    required String notif,
    required List<String> deviceIds,
    LatLng? circleCenter,
    double radius = 100,
    LatLng? rectStart,
    LatLng? rectEnd,
    List<LatLng> polygonPoints = const [],
  }) {
    return _buildPayload(
      mode: mode, name: name, notif: notif, deviceIds: deviceIds,
      circleCenter: circleCenter, radius: radius,
      rectStart: rectStart, rectEnd: rectEnd,
      polygonPoints: polygonPoints,
    );
  }

  // UPDATE (sama + tambah 'id')
  static Map<String, dynamic> buildUpdate({
    required int id,
    required GeofenceDrawMode mode,
    required String name,
    required String notif,
    required List<String> deviceIds,
    LatLng? circleCenter,
    double radius = 100,
    LatLng? rectStart,
    LatLng? rectEnd,
    List<LatLng> polygonPoints = const [],
  }) {
    final payload = _buildPayload(
      mode: mode, name: name, notif: notif, deviceIds: deviceIds,
      circleCenter: circleCenter, radius: radius,
      rectStart: rectStart, rectEnd: rectEnd,
      polygonPoints: polygonPoints,
    );
    return {'id': id, ...payload};
  }

  // Internal
  static Map<String, dynamic> _buildPayload({
    required GeofenceDrawMode mode,
    required String name,
    required String notif,
    required List<String> deviceIds,
    LatLng? circleCenter,
    double radius = 100,
    LatLng? rectStart,
    LatLng? rectEnd,
    List<LatLng> polygonPoints = const [],
  }) {
    final deviceIdsString = deviceIds.join(',');
    final inoutValue = notif == 'in' ? '1' : '0';

    switch (mode) {

      case GeofenceDrawMode.circle:
        if (circleCenter == null) return {};

        // final edgeLat = circleCenter.latitude + (radius / 111320.0);

        return {
          'nama': name,
          'geo_type': _typeCircle,
          'geo_point1': circleCenter.latitude,
          'geo_point2': circleCenter.longitude,
          'geo_point3': radius,
          'geo_point4': 0,
          'geo_point': '${circleCenter.latitude},${circleCenter.longitude},$radius',
          'radius': radius,
          'inout': inoutValue,
          'notifikasi': '1',
          'polygon': '',
          'device_ids': deviceIdsString,
        };

      case GeofenceDrawMode.rectangle:
        if (rectStart == null || rectEnd == null) return {};

        return {
          'nama': name,
          'geo_type': _typeRectangle,
          'geo_point1': rectStart.latitude,
          'geo_point2': rectStart.longitude,
          'geo_point3': rectEnd.latitude,
          'geo_point4': rectEnd.longitude,
          'geo_point': '${rectStart.latitude},${rectStart.longitude},${rectEnd.latitude},${rectEnd.longitude}',
          'inout': inoutValue,
          'notifikasi': '1',
          'polygon': _toWkt(_rectToPoints(rectStart, rectEnd)),
          'device_ids': deviceIdsString,
        };

      case GeofenceDrawMode.polygon:
        if (polygonPoints.length < 3) return {};

        final bbox = _boundingBox(polygonPoints);

        return {
          'nama': name,
          'geo_type': _typePolygon,
          'geo_point1': bbox['lat_min'],
          'geo_point2': bbox['lng_min'],
          'geo_point3': bbox['lat_max'],
          'geo_point4': bbox['lng_max'],
          'geo_point': polygonPoints
              .map((p) => '${p.latitude},${p.longitude}')
              .join('|'),
          'inout': inoutValue,
          'notifikasi': '1',
          'polygon': _toWkt(polygonPoints),
          'device_ids': deviceIdsString,
        };

      case GeofenceDrawMode.pan:
        return {};
    }
  }

  // Helpers
  static List<LatLng> _rectToPoints(LatLng a, LatLng b) => [
    LatLng(a.latitude, a.longitude),
    LatLng(a.latitude, b.longitude),
    LatLng(b.latitude, b.longitude),
    LatLng(b.latitude, a.longitude),
    LatLng(a.latitude, a.longitude),
  ];

  static String _toWkt(List<LatLng> pts) {
    final coords = pts.map((p) => '${p.longitude} ${p.latitude}').join(', ');
    return 'POLYGON(($coords))';
  }

  static Map<String, double> _boundingBox(List<LatLng> pts) {
    final lats = pts.map((p) => p.latitude).toList();
    final lngs = pts.map((p) => p.longitude).toList();
    return {
      'lat_min': lats.reduce((a, b) => a < b ? a : b),
      'lat_max': lats.reduce((a, b) => a > b ? a : b),
      'lng_min': lngs.reduce((a, b) => a < b ? a : b),
      'lng_max': lngs.reduce((a, b) => a > b ? a : b),
    };
  }
}