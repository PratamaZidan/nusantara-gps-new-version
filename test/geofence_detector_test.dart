import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/utils/geofence_detector.dart';

void main() {

  // ─── Circle ────────────────────────────────────────────────────────────────

  group('isInsideCircle', () {
    test('titik tepat di pusat → dalam', () {
      expect(
        GeofenceDetector.isInsideCircle(
          point: LatLng(-7.936738, 112.617612),
          center: LatLng(-7.936738, 112.617612),
          radiusInMeters: 100,
        ),
        true,
      );
    });

    test('titik jauh dari pusat → luar', () {
      expect(
        GeofenceDetector.isInsideCircle(
          point: LatLng(-7.936738, 112.617612),
          center: LatLng(-8.000000, 112.700000),
          radiusInMeters: 100,
        ),
        false,
      );
    });

    test('titik tepat di batas radius → dalam (≤)', () {
      // haversineDistance antara dua titik ini ≈ 100 m
      const center = LatLng(-7.936738, 112.617612);
      // ~100 m ke Utara ≈ 0.0009° lintang
      const onEdge = LatLng(-7.935838, 112.617612);
      final dist = GeofenceDetector.haversineDistance(
        center.latitude, center.longitude,
        onEdge.latitude, onEdge.longitude,
      );
      expect(
        GeofenceDetector.isInsideCircle(
          point: onEdge,
          center: center,
          radiusInMeters: dist, // tepat di batas
        ),
        true,
      );
    });
  });

  // ─── Polygon ───────────────────────────────────────────────────────────────
  //
  // Kotak sederhana: sudut SW(-8.001, 112.60), NE(-7.999, 112.602)
  // Lebar ≈ 220 m, tinggi ≈ 222 m
  //
  //   NW ──── NE
  //   │          │
  //   SW ──── SE
  //
  final box = [
    LatLng(-8.001, 112.600), // SW
    LatLng(-8.001, 112.602), // SE
    LatLng(-7.999, 112.602), // NE
    LatLng(-7.999, 112.600), // NW
  ];

  group('isInsidePolygon', () {
    test('titik di tengah kotak → dalam', () {
      expect(
        GeofenceDetector.isInsidePolygon(
          point: LatLng(-8.000, 112.601), // tepat di tengah
          vertices: box,
        ),
        true,
      );
    });

    test('titik di luar kotak (Barat) → luar', () {
      expect(
        GeofenceDetector.isInsidePolygon(
          point: LatLng(-8.000, 112.598), // di sebelah barat
          vertices: box,
        ),
        false,
      );
    });

    test('titik di luar kotak (Utara) → luar', () {
      expect(
        GeofenceDetector.isInsidePolygon(
          point: LatLng(-7.997, 112.601), // di sebelah utara
          vertices: box,
        ),
        false,
      );
    });

    test('titik di luar kotak (Selatan) → luar', () {
      expect(
        GeofenceDetector.isInsidePolygon(
          point: LatLng(-8.003, 112.601), // di sebelah selatan
          vertices: box,
        ),
        false,
      );
    });

    test('titik di luar kotak (Timur) → luar', () {
      expect(
        GeofenceDetector.isInsidePolygon(
          point: LatLng(-8.000, 112.605), // di sebelah timur
          vertices: box,
        ),
        false,
      );
    });

    test('polygon kurang dari 3 titik → false', () {
      expect(
        GeofenceDetector.isInsidePolygon(
          point: LatLng(-8.000, 112.601),
          vertices: [LatLng(-8.001, 112.600), LatLng(-7.999, 112.602)],
        ),
        false,
      );
    });

    test('polygon kosong → false', () {
      expect(
        GeofenceDetector.isInsidePolygon(
          point: LatLng(-8.000, 112.601),
          vertices: [],
        ),
        false,
      );
    });

    // Verifikasi sumbu tidak tertukar:
    // Jika lat/lng dibalik, titik yang seharusnya DALAM akan terdeteksi LUAR.
    // Test ini memastikan bug sumbu tertukar tidak muncul lagi.
    test('sumbu tidak tertukar — titik dalam terdeteksi benar', () {
      // Titik ini jelas dalam kotak jika lat=x,lng=y benar,
      // tapi akan jadi LUAR jika sumbu tertukar (longitude jadi y-axis)
      final inside = GeofenceDetector.isInsidePolygon(
        point: LatLng(-8.0005, 112.6015),
        vertices: box,
      );
      final outside = GeofenceDetector.isInsidePolygon(
        point: LatLng(-8.0005, 112.5990), // jelas di luar (Barat)
        vertices: box,
      );
      expect(inside, true,  reason: 'Titik dalam kotak harus terdeteksi DALAM');
      expect(outside, false, reason: 'Titik luar kotak harus terdeteksi LUAR');
    });
  });

  // ─── Haversine ─────────────────────────────────────────────────────────────

  group('haversineDistance', () {
    test('jarak titik ke dirinya sendiri = 0', () {
      expect(
        GeofenceDetector.haversineDistance(-8.0, 112.0, -8.0, 112.0),
        0.0,
      );
    });

    test('jarak ~1 km antara dua titik', () {
      // Titik di sekitar Banyuwangi — ~1668 m sesuai contoh di proposal
      final dist = GeofenceDetector.haversineDistance(
        -8.2232875, 114.3661375,
        -8.2123176, 114.3764785,
      );
      // Toleransi ±50 m dari 1668 m
      expect(dist, greaterThan(1600));
      expect(dist, lessThan(1720));
    });
  });
}