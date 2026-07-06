import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/data/models/position.dart';

class MarkerCluster {
  final LatLng position;
  final List<int> deviceIds;

  const MarkerCluster({required this.position, required this.deviceIds});

  int get count => deviceIds.length;
  bool get isSingle => deviceIds.length == 1;
}

class CustomClusterManager {
  CustomClusterManager._();

  static double _clusterRadius(double zoom) {
    // Jangan cluster kalau sudah dekat (zoom >= 15)
    if (zoom >= 15) return 0.0;

    const pixelRadius = 60.0; // radius cluster dalam pixel
    const tileSize    = 256.0;
    final degPerTile  = 360.0 / math.pow(2, zoom);
    return (pixelRadius / tileSize) * degPerTile;
  }

  static List<MarkerCluster> cluster({
    required Map<int, PositionModel> positions,
    required double zoom,
  }) {
    if (positions.isEmpty) return [];

    final radius = _clusterRadius(zoom);

    // Kalau zoom sangat dekat (radius = 0), setiap kendaraan jadi marker sendiri
    if (radius == 0.0) {
      return positions.entries.map((e) => MarkerCluster(
        position: LatLng(e.value.latitude, e.value.longitude),
        deviceIds: [e.key],
      )).toList();
    }

    final List<MarkerCluster> clusters = [];
    final Set<int> processed = {};

    for (final entry in positions.entries) {
      if (processed.contains(entry.key)) continue;

      final pos = entry.value;
      final List<int> group = [entry.key];
      processed.add(entry.key);

      for (final other in positions.entries) {
        if (processed.contains(other.key)) continue;

        final dist = _distanceDeg(
          pos.latitude, pos.longitude,
          other.value.latitude, other.value.longitude,
        );

        if (dist <= radius) {
          group.add(other.key);
          processed.add(other.key);
        }
      }

      // Centroid cluster
      double sumLat = 0, sumLng = 0;
      for (final id in group) {
        sumLat += positions[id]!.latitude;
        sumLng += positions[id]!.longitude;
      }

      clusters.add(MarkerCluster(
        position: LatLng(sumLat / group.length, sumLng / group.length),
        deviceIds: group,
      ));
    }

    return clusters;
  }

  // Jarak Euclidean dalam derajat (cukup akurat untuk area kecil)
  static double _distanceDeg(
      double lat1, double lng1, double lat2, double lng2) {
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    // Koreksi longitude karena 1° lng != 1° lat di lintang tertentu
    final cosLat = math.cos((lat1 + lat2) / 2 * math.pi / 180);
    return math.sqrt(dLat * dLat + (dLng * cosLat) * (dLng * cosLat));
  }
}