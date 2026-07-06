import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // Channel untuk alert kendaraan
  static const AndroidNotificationChannel _alertChannel = AndroidNotificationChannel(
    'vehicle_alerts',
    'Alert Kendaraan',
    description: 'Notifikasi alarm dan peringatan dari kendaraan',
    importance: Importance.high,
  );

  bool _initialized = false;

  // Init
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Buat Channel Android (wajib android 8+)
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_alertChannel);

    // Request permission Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // Show Notification
  Future<void> showAlertNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    final androidDetails = AndroidNotificationDetails(
      _alertChannel.id,
      _alertChannel.name,
      channelDescription: _alertChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      groupKey: 'vehicle_alerts_group', // Grouping notifikasi jika banyak alert
    );

    await _plugin.show(
      id.hashCode, 
      title, 
      body, 
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  void _onTap(NotificationResponse response) {
    print('[Notif Tap] payload: ${response.payload}'); 
  }
}