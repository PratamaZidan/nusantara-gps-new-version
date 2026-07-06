import 'package:google_maps_flutter/google_maps_flutter.dart';

extension WktPolygonParser on String {
  List<LatLng> toLatLngPolygon() {
    final cleaned = replaceAll('POLYGON((', '')
        .replaceAll('POLYGON ((', '')
        .replaceAll('))', '')
        .trim();

    if (cleaned.isEmpty) return [];

    return cleaned.split(',').map((point) {
      final coords = point.trim().split(RegExp(r'\s+'));
      if (coords.length != 2) {
        throw FormatException('Invalid WKT coordinate: $point');
      }

      final lng = double.parse(coords[0]); 
      final lat = double.parse(coords[1]); 
      return LatLng(lat, lng);
    }).toList();
  }
}

extension PipePolygonParser on String {
  List<LatLng> toPipeLatLngPolygon() {
    final cleaned = trim();
    if (cleaned.isEmpty || cleaned == '0') return [];

    return cleaned.split('|').map((point) {
      final coords = point.trim().split(',');
      if (coords.length < 2) {
        throw FormatException('Invalid pipe coordinate: $point');
      }

      final lat = double.parse(coords[0]);
      final lng = double.parse(coords[1]);
      return LatLng(lat, lng);
    }).toList();
  }

  bool get isWktPolygon => toUpperCase().startsWith('POLYGON');

  bool get isPipePolygon => contains('|') && !isWktPolygon;
}