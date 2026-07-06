import 'package:flutter_test/flutter_test.dart';
import 'package:nusantara_gps/core/utils/geofence_status_tracker.dart';

void main() {
  final tracker = GeofenceStatusTracker.instance;

  late DateTime fakeNow;

  setUp(() {
    tracker.reset();

    // waktu awal
    fakeNow = DateTime(2024, 1, 1, 0, 0, 0);

    // inject waktu
    tracker.now = () => fakeNow;
  });

  // ================= BASIC =================
  test('tidak trigger saat pertama kali detect', () {
    final event = tracker.checkAndUpdate(
      deviceId: 'A',
      geofenceId: 1,
      geofenceName: 'Area 1',
      deviceName: 'Mobil A',
      isCurrentlyInside: true,
    );

    expect(event, null);
  });

  test('trigger saat masuk setelah sebelumnya di luar', () {
    // 1. init (unknown → outside)
    tracker.checkAndUpdate(
      deviceId: 'A',
      geofenceId: 1,
      geofenceName: 'Area 1',
      deviceName: 'Mobil A',
      isCurrentlyInside: false,
    );

    // 2. stabil (outside lagi, biar state fix)
    fakeNow = fakeNow.add(Duration(seconds: 31));
    tracker.checkAndUpdate(
      deviceId: 'A',
      geofenceId: 1,
      geofenceName: 'Area 1',
      deviceName: 'Mobil A',
      isCurrentlyInside: false,
    );

    // 3. baru masuk
    fakeNow = fakeNow.add(Duration(seconds: 31));
    final event = tracker.checkAndUpdate(
      deviceId: 'A',
      geofenceId: 1,
      geofenceName: 'Area 1',
      deviceName: 'Mobil A',
      isCurrentlyInside: true,
    );

    expect(event != null, true);
    expect(event!.isEntering, true);
  });

  test('tidak trigger kalau masih dalam cooldown', () {
    // 1. init (unknown -> outside)
    tracker.checkAndUpdate(
      deviceId: 'A',
      geofenceId: 1,
      geofenceName: 'Area 1',
      deviceName: 'Mobil A',
      isCurrentlyInside: false,
    );

    // 2. Ubah status ke inside (lewat dari 30s sejak inisialisasi agar terpicu)
    fakeNow = fakeNow.add(Duration(seconds: 31));
    final event1 = tracker.checkAndUpdate(
      deviceId: 'A',
      geofenceId: 1,
      geofenceName: 'Area 1',
      deviceName: 'Mobil A',
      isCurrentlyInside: true,
    );
    expect(event1 != null, true);

    // 3. Coba ubah status kembali ke outside dalam waktu cooldown (hanya 10 detik kemudian)
    fakeNow = fakeNow.add(Duration(seconds: 10));

    final event2 = tracker.checkAndUpdate(
      deviceId: 'A',
      geofenceId: 1,
      geofenceName: 'Area 1',
      deviceName: 'Mobil A',
      isCurrentlyInside: false,
    );

    expect(event2, null);
  });

  // ================= SIMULASI =================
  test('simulasi kendaraan masuk lalu keluar geofence', () {
    final states = [false, false, true, true, false];
    final events = [];

    for (final state in states) {
      final event = tracker.checkAndUpdate(
        deviceId: 'A',
        geofenceId: 1,
        geofenceName: 'Area Test',
        deviceName: 'Mobil A',
        isCurrentlyInside: state,
      );

      if (event != null) {
        events.add(event);
      }

      // majuin waktu tiap step
      fakeNow = fakeNow.add(Duration(seconds: 31));
    }

    expect(events.length, 2);
    expect(events[0].isEntering, true);
    expect(events[1].isEntering, false);
  });

  // ================= JITTER =================
  test('tidak spam akibat GPS jitter di batas geofence', () {
    final jitterStates = [false, false, true, false, true, false];

    int eventCount = 0;

    for (final state in jitterStates) {
      final event = tracker.checkAndUpdate(
        deviceId: 'A',
        geofenceId: 1,
        geofenceName: 'Area Jitter',
        deviceName: 'Mobil A',
        isCurrentlyInside: state,
      );

      if (event != null) eventCount++;

      fakeNow = fakeNow.add(Duration(seconds: 5));
    }

    expect(eventCount <= 1, true);
  });
}