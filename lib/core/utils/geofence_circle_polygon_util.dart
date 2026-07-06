import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofenceCirclePolygonUtil {
  static const double _earthRadius = 6371000; // Radius bumi dalam meter

  static List<LatLng> generatePolygon({
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
    int numPoints = 36, // Jumlah titik untuk membentuk polygon (semakin banyak, semakin halus)
  }) {
    final latRad = _degToRad(centerLat);
    final lngRad = _degToRad(centerLng);
    final angularDistance = radiusMeters / _earthRadius;

    final points = <LatLng>[];

    for (int i = 0; i < numPoints; i++) {
      final bearing = 2 * math.pi * i / numPoints; // Sudut dalam radian

      final pointLat = math.asin(
        math.sin(latRad) * math.cos(angularDistance) +
        math.cos(latRad) * math.sin(angularDistance) * math.cos(bearing)
      );

      final pointLng = lngRad +
        math.atan2(
          math.sin(bearing) * math.sin(angularDistance) * math.cos(latRad),
          math.cos(angularDistance) - math.sin(latRad) * math.sin(pointLat),
        );

      points.add(LatLng(_radToDeg(pointLat), _radToDeg(pointLng)));
    }

    if (points.isNotEmpty) {
      points.add(points.first); // Menutup polygon dengan menambahkan titik pertama di akhir
    }

    return points;
  }

  static double _degToRad(double degrees) => degrees * math.pi / 180;
  static double _radToDeg(double radians) => radians * 180 / math.pi;
}