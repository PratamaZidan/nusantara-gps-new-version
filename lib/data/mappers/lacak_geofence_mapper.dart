import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/utils/polygon_extention.dart';
import 'package:nusantara_gps/data/dto/geofence_lacak_dto.dart';
import 'package:nusantara_gps/data/models/geofence_model.dart';

class LacakGeofenceMapper {

  static List<GeofenceModel> toEntities(dynamic raw) {
    final normalized = _normalizeJson(raw);
    final List root = (normalized is Map && normalized['root'] is List)
        ? normalized['root'] as List
        : const [];

    final all = root
        .whereType<Map>()
        .map((e) => GeofenceLacakDto.fromJson(Map<String, dynamic>.from(e)))
        .map(_toEntity)
        .toList();

    final valid = all.where((e) => e.polygon.isNotEmpty).toList();

    if (all.length != valid.length) {
      debugPrint(
        '[GeofenceMapper] ${all.length - valid.length} geofence dibuang '
        'karena polygon kosong/tidak bisa diparse. '
        'Total: ${all.length}, valid: ${valid.length}',
      );
    }

    return valid;
  }

  static GeofenceModel _toEntity(GeofenceLacakDto dto) {
    final polygon = _resolvePolygon(dto);

    double? centerLat;
    double? centerLng;
    double? radius;

    if (dto.geotype == '1') {
      // Circle: center = lat1/lng1, radius = point3 (meter langsung dari API)
      centerLat = dto.lat1;
      centerLng = dto.lng1;
      radius = dto.radiusMeters > 10 ? dto.radiusMeters : 100.0;
    } else {
      if (polygon.isNotEmpty) {
        centerLat = polygon.map((p) => p.latitude).reduce((a, b) => a + b) / polygon.length;
        centerLng = polygon.map((p) => p.longitude).reduce((a, b) => a + b) / polygon.length;
      }
    }

    return GeofenceModel(
      id:           dto.id,
      name:         dto.name,
      polygon:      polygon,
      areaRaw:      dto.polygonRaw,
      centerLat:    centerLat,
      centerLng:    centerLng,
      radiusMeters: radius,
      geoType:      dto.geotype,
      inout:        dto.inout ?? '1',
      deviceIds:    dto.deviceIds,
    );
  }

  static List<LatLng> _resolvePolygon(GeofenceLacakDto dto) {

    // geo_type "1" = CIRCLE 
    if (dto.geotype == '1') {
      final double radius = dto.radiusMeters > 10 ? dto.radiusMeters : 100.0;
      return _generateCirclePolygon(
        centerLat: dto.lat1,
        centerLng: dto.lng1,
        radiusMeters: radius,
      );
    }

    final raw = dto.polygonRaw.trim();

    if (raw.isNotEmpty && raw != '0') {
      if (raw.isPipePolygon) {
        try {
          final parsed = raw.toPipeLatLngPolygon();
          if (parsed.length >= 3) return parsed;
        } catch (_) {}
      }

      // Parse WKT
      if (raw.isWktPolygon) {
        try {
          final parsed = raw.toLatLngPolygon();
          if (parsed.length >= 3) return parsed;
        } catch (_) {}
      }
    }

    // Fallback: bangun dari geo_point1-4 (rectangle)
    // Hanya berlaku jika ada koordinat valid (bukan semua 0)
    if (dto.lat1 != 0 && dto.lng1 != 0 && dto.lat2 != 0 && dto.lng2 != 0) {
      return _buildRectanglePolygon(
        lat1: dto.lat1, lng1: dto.lng1,
        lat2: dto.lat2, lng2: dto.lng2,
      );
    }

    return [];
  }

  // Circle polygon generator (36 titik)
  static List<LatLng> _generateCirclePolygon({
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
    int sides = 36,
  }) {
    const earthRadius = 6371000.0;
    final latRad = centerLat * math.pi / 180;
    final lngRad = centerLng * math.pi / 180;
    final angularDist = radiusMeters / earthRadius;

    final points = <LatLng>[];
    for (int i = 0; i < sides; i++) {
      final bearing = 2 * math.pi * i / sides;
      final pointLat = math.asin(
        math.sin(latRad) * math.cos(angularDist) +
        math.cos(latRad) * math.sin(angularDist) * math.cos(bearing),
      );
      final pointLng = lngRad + math.atan2(
        math.sin(bearing) * math.sin(angularDist) * math.cos(latRad),
        math.cos(angularDist) - math.sin(latRad) * math.sin(pointLat),
      );
      points.add(LatLng(pointLat * 180 / math.pi, pointLng * 180 / math.pi));
    }
    if (points.isNotEmpty) points.add(points.first);
    return points;
  }

  static List<LatLng> _buildRectanglePolygon({
    required double lat1, required double lng1,
    required double lat2, required double lng2,
  }) {
    final south = lat1 < lat2 ? lat1 : lat2;
    final north = lat1 > lat2 ? lat1 : lat2;
    final west  = lng1 < lng2 ? lng1 : lng2;
    final east  = lng1 > lng2 ? lng1 : lng2;
    return [
      LatLng(south, west),
      LatLng(south, east),
      LatLng(north, east),
      LatLng(north, west),
      LatLng(south, west),
    ];
  }

  static dynamic _normalizeJson(dynamic raw) {
    if (raw is String) return jsonDecode(raw);
    return raw;
  }
}