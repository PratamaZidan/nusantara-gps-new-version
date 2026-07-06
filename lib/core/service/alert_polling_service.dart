import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nusantara_gps/core/service/geofence_event_store.dart';
import 'package:nusantara_gps/core/utils/geofence_detector.dart';
import 'package:nusantara_gps/core/utils/geofence_status_tracker.dart';
import 'package:nusantara_gps/core/service/service_health_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertPollingService {
  AlertPollingService._();
  static final AlertPollingService instance = AlertPollingService._();

  Future<void> initAndStart() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStartBackground,
        autoStart: true,
        isForegroundMode: true,
        autoStartOnBoot: true,
        foregroundServiceNotificationId: 888,
        notificationChannelId: 'alert_polling',
        initialNotificationTitle: 'Nusantara GPS',
        initialNotificationContent: 'Memantau notifikasi kendaraan',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStartBackground,
      ),
    );

    await service.startService();
  }

  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}

// Top-level (diperlukan flutter_background_service)
@pragma('vm:entry-point')
void onStartBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();

    service.setForegroundNotificationInfo(
      title: 'Nusantara GPS',
      content: 'Memantau Kendaraan...',
    );
  }

  int _alertErrorCount = 0;
  int _geofenceErrorCount = 0;

  try {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('geofence_events')) {
      await Hive.openBox('geofence_events');
    }

    final notifPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('ic_notif');
    await notifPlugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    final androidImpl = notifPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      'vehicle_alerts',
      'Alert Kendaraan',
      description: 'Notifikasi alarm dari kendaraan',
      importance: Importance.high,
    ));

    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      'geofence_alerts',
      'Peringatan Geofence',
      description: 'Notifikasi saat kendaraan masuk atau keluar area geofence',
      importance: Importance.high,
    ));

    await ServiceHealthStore.instance.recordServiceStart();

    await notifPlugin.show(
      888,
      'Nusantara GPS Aktif',
      'Memantau Kendaraan...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alert_polling',
          'Nusantara GPS Service',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          icon: 'ic_notif',
        ),
      ),
    );

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    Timer.periodic(const Duration(minutes: 5), (_) async {
      try {
        await _pollAlerts(notifPlugin);
        _alertErrorCount = 0; 
      } catch (e) {
        _alertErrorCount++;
        await ServiceHealthStore.instance.recordError('AlertPolling', e);
      }
    });

    Timer.periodic(const Duration(minutes: 2), (_) async {
      try {
        await _pollGeofenceDetection(notifPlugin, service);
        _geofenceErrorCount = 0;
      } catch (e) {
        _geofenceErrorCount++;
        await ServiceHealthStore.instance.recordError('GeofencePolling', e);
      }
    });

    Future.delayed(const Duration(seconds: 10), () async {
      try {
        await _pollAlerts(notifPlugin);
        await _pollGeofenceDetection(notifPlugin, service);
      } catch (e) {
        print('[BackgroundService] Initial Poll Error: $e');
      }
    });

  } catch (e) {
    print('[BackgroundService] Init Error: $e');
  }
}

// Alert Polling (hardware alarm)
Future<void> _pollAlerts(FlutterLocalNotificationsPlugin notifPlugin) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString('notif.last_alert_id') ?? '0';
    final dio = _buildDio(prefs);

    final response = await dio.get(
      'hrpc.php',
      queryParameters: {'act': 'listalert'},
    );

    final data = _parseResponse(response.data);
    final List root = data['root'] ?? [];
    if (root.isEmpty) return;

    // Catat waktu cek alert berhasil
    await ServiceHealthStore.instance.recordAlertCheck();

    final latestId = root.first['id']?.toString() ?? '0';
    if (latestId == lastId) return;

    final newAlerts = root.where((a) {
      final id = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
      final last = int.tryParse(lastId) ?? 0;
      return id > last;
    }).toList();

    for (int i = 0; i < newAlerts.length && i < 3; i++) {
      final alert = newAlerts[i] as Map<String, dynamic>;
      final deviceName = alert['devicename']?.toString() ?? 'Kendaraan';
      final message = alert['message']?.toString() ?? '';
      final alertId = alert['id']?.toString() ?? '';

      await notifPlugin.show(
        alertId.hashCode,
        'Alert: $deviceName',
        _formatMessage(message),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'vehicle_alerts',
            'Alert Kendaraan',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notif',
          ),
        ),
        payload: jsonEncode(alert),
      );
    }

    await prefs.setString('notif.last_alert_id', latestId);
  } catch (e) {
    await ServiceHealthStore.instance.recordError('AlertPolling', e);
    print('[AlertPolling] Error: $e');
  }
}

// Geofence Detection Polling
Future<void> _pollGeofenceDetection(
    FlutterLocalNotificationsPlugin notifPlugin,
    ServiceInstance service // Untuk update notif foreground
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final dio   = _buildDio(prefs);

    // 1. Ambil list geofence aktif
    final geofenceResponse = await dio.get(
      'hrpc.php',
      queryParameters: {'act': 'listgeofence'},
    );
    final geofenceData = _parseResponse(geofenceResponse.data);
    final List geofences = geofenceData['root'] ?? [];
    if (geofences.isEmpty) return;

    // 2. Ambil posisi semua kendaraan terkini
    final positionResponse = await dio.get(
      'hrpc.php',
      queryParameters: {'act': 'listkejadian', 'ids': '', 'kode': '', 'catid': '0'},
    );
    final positionData = _parseResponse(positionResponse.data);
    final List positions = positionData['root'] ?? [];
    if (positions.isEmpty) return;

    // Catat waktu cek geofence berhasil
    await ServiceHealthStore.instance.recordGeofenceCheck();

    // 3. Cek setiap kendaraan terhadap setiap geofence
    for (final rawPos in positions) {
      final pos = rawPos as Map<String, dynamic>;
      final deviceId = pos['deviceid']?.toString() ?? '';
      final deviceName = pos['marker']?['device']?.toString()
          ?? pos['deviceid']?.toString()
          ?? 'Kendaraan';
      final lat = _parseDouble(pos['lat']);
      final lng = _parseDouble(pos['lng']);

      if (lat == 0.0 && lng == 0.0) continue;
      final vehiclePos = LatLng(lat, lng);

      for (final rawGeo in geofences) {
        final geo = rawGeo as Map<String, dynamic>;
        final geofenceId = int.tryParse(geo['id']?.toString() ?? '0') ?? 0;
        final geofenceName = geo['nama']?.toString() ?? 'Geofence';
        final geoType = geo['geo_type']?.toString() ?? '0';

        bool isInside = false;

        if (geoType == '1') {
          // Circle
          final centerLat = _parseDouble(geo['geo_point1']);
          final centerLng = _parseDouble(geo['geo_point2']);
          final radius = _parseDouble(geo['geo_point3']);

          if (centerLat != 0 && centerLng != 0 && radius > 0) {
            isInside = GeofenceDetector.isInsideCircle(
              point: vehiclePos,
              center: LatLng(centerLat, centerLng),
              radiusInMeters: radius,
            );
          }
        } else {
          // Polygon / Rectangle
          final polygonRaw = geo['polygon']?.toString() ?? '';
          final vertices = _parsePolygon(polygonRaw);

          if (vertices.length >= 3) {
            isInside = GeofenceDetector.isInsidePolygon(
              point: vehiclePos,
              vertices: vertices,
            );
          } else if (geoType == '2') {
            // Rectangle dari 4 geo_points
            final lat1 = _parseDouble(geo['geo_point1']);
            final lng1 = _parseDouble(geo['geo_point2']);
            final lat2 = _parseDouble(geo['geo_point3']);
            final lng2 = _parseDouble(geo['geo_point4']);

            if (lat1 != 0 && lat2 != 0) {
              isInside = GeofenceDetector.isInsidePolygon(
                point: vehiclePos,
                vertices: [
                  LatLng(lat1, lng1),
                  LatLng(lat1, lng2),
                  LatLng(lat2, lng2),
                  LatLng(lat2, lng1),
                ],
              );
            }
          }
        }

        // 4. Cek apakah status berubah → trigger notif + simpan ke Hive
        final event = GeofenceStatusTracker.instance.checkAndUpdate(
          deviceId: deviceId,
          geofenceId: geofenceId,
          geofenceName: geofenceName,
          deviceName: deviceName,
          isCurrentlyInside: isInside,
        );

        if (event != null) {
          // Simpan ke Hive supaya muncul di halaman alert tab Geofence
          final store = GeofenceEventStore();
          final eventId = '${deviceId}_${geofenceId}_${DateTime.now().millisecondsSinceEpoch}';
          await store.saveEvent(GeofenceEventModel(
            id: eventId,
            deviceId: deviceId,
            deviceName: deviceName,
            geofenceId: geofenceId.toString(),
            geofenceName: geofenceName,
            isEntering: event.isEntering,
            timestamp: DateTime.now().toIso8601String().split('.').first.replaceAll('T', ' '),
          ));

          // System notification
          await notifPlugin.show(
            '${deviceId}_$geofenceId'.hashCode,
            event.title,
            event.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'geofence_alerts',
                'Peringatan Geofence',
                importance: Importance.high,
                priority: Priority.high,
                icon: 'ic_notif',
              ),
            ),
            payload: jsonEncode({
              'type': 'geofence',
              'deviceId': deviceId,
              'deviceName': deviceName,
              'geofenceId': geofenceId,
              'geofenceName': geofenceName,
              'isEntering': event.isEntering,
            }),
          );
        }
      }
    }

    // Update notifikasi foreground dg timestamp cek terakhir
    await notifPlugin.show(
      888,
      'Nusantara GPS Aktif',
      'Cek terakhir: ${_formatTime(DateTime.now())}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alert_polling',
          'Nusantara GPS Service',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          icon: 'ic_notif',
        ),
      ),
    );
  } catch (e) {
    await ServiceHealthStore.instance.recordError('GeofencePolling', e);
    print('[GeofencePolling] Error: $e');
  }
}

// Helpers (top-level)
Dio _buildDio(SharedPreferences prefs) {
  final phpSessId = prefs.getString('auth.phpsessid') ?? '';
  return Dio(BaseOptions(
    baseUrl: 'https://lacak.nusantaragps.com/assets/API/',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Accept': 'application/json',
      if (phpSessId.isNotEmpty) 'cookie': 'PHPSESSID=$phpSessId',
    },
  ));
}

dynamic _parseResponse(dynamic data) {
  if (data is String) return jsonDecode(data);
  return data;
}

double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

List<LatLng> _parsePolygon(String raw) {
  final cleaned = raw.trim();
  if (cleaned.isEmpty || cleaned == '0') return [];

  if (cleaned.contains('|')) {
    try {
      return cleaned.split('|').map((p) {
        final parts = p.trim().split(',');
        return LatLng(double.parse(parts[0]), double.parse(parts[1]));
      }).toList();
    } catch (_) {}
  }

  if (cleaned.toUpperCase().startsWith('POLYGON')) {
    try {
      final inner = cleaned
          .replaceAll('POLYGON((', '')
          .replaceAll('POLYGON ((', '')
          .replaceAll('))', '')
          .trim();
      return inner.split(',').map((p) {
        final coords = p.trim().split(RegExp(r'\s+'));
        return LatLng(double.parse(coords[1]), double.parse(coords[0]));
      }).toList();
    } catch (_) {}
  }

  return [];
}

String _formatMessage(String raw) {
  final msg = raw.toUpperCase();
  if (msg.contains('SHOCK')) return 'Kendaraan terdeteksi benturan/guncangan';
  if (msg.contains('POWER_CUT')) return 'Koneksi GPS Terputus';
  if (msg.contains('SOS')) return 'Tombol SOS ditekan';
  if (msg.contains('OVERSPEED')) return 'Kecepatan berlebih terdeteksi';
  if (msg.contains('GEOFENCE')) return 'Pelanggaran area geofence';
  return raw;
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}