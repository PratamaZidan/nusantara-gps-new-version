import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Logika kalkulasi deteksi posisi terhadap area geofence
class GeofenceDetector {
  GeofenceDetector._();

  // Circle Detection
  static bool isInsideCircle({
    required LatLng point,
    required LatLng center,
    required double radiusInMeters,
  }) {
    final distance = haversineDistance(
      point.latitude, point.longitude,
      center.latitude, center.longitude,
    );
    return distance <= radiusInMeters;
  }

  // Polygon Detection — Ray Casting Algorithm
  // Konvensi koordinat:
  //   x = longitude (sumbu horizontal)
  //   y = latitude  (sumbu vertikal)
  // Keduanya HARUS konsisten antara point dan vertices.
  // JANGAN tukar lat↔lng di sini — pernah jadi bug sebelumnya.
  static bool isInsidePolygon({
    required LatLng point,
    required List<LatLng> vertices,
  }) {
    if (vertices.length < 3) return false; // polygon ga valid

    final x = point.longitude;  // horizontal
    final y = point.latitude;   // vertikal
    bool inside = false;

    int j = vertices.length - 1; // index terakhir
    for (int i = 0; i < vertices.length; i++) {
      final xi = vertices[i].longitude; // horizontal, sama dengan x
      final yi = vertices[i].latitude;  // vertikal,   sama dengan y
      final xj = vertices[j].longitude;
      final yj = vertices[j].latitude;

      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi);

      if (intersect) inside = !inside;
      j = i; // next pair
    }

    return inside;
  }

  // Haversine Distance
  static double haversineDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const earthRadius = 6371000; // dalam meter
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
        math.cos(_toRad(lat2)) *
        math.sin(dLng / 2) *
        math.sin(dLng / 2);

    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double degree) => degree * math.pi / 180;
}