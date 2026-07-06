import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofenceWktUtil {
  static String polygonToWkt(List<LatLng> points) {
    if (points.length < 4) {
      throw FormatException('Polygon harus memiliki minimal 4 titik.');
    }

    final coords = points
        .map((p) => '${p.longitude} ${p.latitude}')
        .join(', ');

    return 'POLYGON(($coords))';
  }
}