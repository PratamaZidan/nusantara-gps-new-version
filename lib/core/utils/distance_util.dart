import 'dart:math';

double distanceInMeters({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const double R = 6371000; // jari-jari bumi dalam meter
  final double dLat = _degToRad(lat2 - lat1);
  final double dLon = _degToRad(lon2 - lon1);

  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) *
          cos(_degToRad(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _degToRad(double deg) => deg * pi / 180;

double normalizeMileageToKm(dynamic raw) {
  if (raw == null) return 0.0;

  final cleaned = raw.toString().replaceAll(',', '').trim();
  final meters = double.tryParse(cleaned) ?? 0.0;

  return meters / 1000.0;
}

/// Kalau butuh ambil raw meter dari API tanpa konversi.
double parseDistanceMeters(dynamic raw) {
  if (raw == null) return 0.0;

  final cleaned = raw.toString().replaceAll(',', '').trim();
  return double.tryParse(cleaned) ?? 0.0;
}

extension ReadableDistance on num {
  String toReadableDistance() {
    final meters = this;

    if (meters < 1000) {
      return "${meters.toStringAsFixed(0)} m";
    }

    final km = (meters / 1000).floor();
    final remainingMeters = (meters - km * 1000).round();

    if (remainingMeters == 0) {
      return "$km km";
    }

    return "$km km $remainingMeters m";
  }

  String toKmOdometer({int fractionDigits = 2}) {
    return '${toStringAsFixed(fractionDigits)} km';
  }
}