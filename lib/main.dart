import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/service/alert_polling_service.dart';
import 'package:nusantara_gps/core/service/notification_service.dart';
import 'package:nusantara_gps/presentation/navigation/app_route.dart';
import 'package:nusantara_gps/core/di/dependency_injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  setupLocator();

  final notifPlugin = FlutterLocalNotificationsPlugin();
  await notifPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  final androidImpl = notifPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  await androidImpl?.createNotificationChannel(
    const AndroidNotificationChannel(
      'alert_polling',
      'Nusantara GPS Service',
      description: 'Foreground service untuk pemantauan kendaraan',
      importance: Importance.low,
    ),
  );

  await AlertPollingService.instance.initAndStart();

  await Hive.initFlutter();
  await Hive.openBox('poi_images');
  await Hive.openBox('geofence_events');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'NusantaraGPS',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          scrolledUnderElevation: 0,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColorTheme.primary),
      ),
      routerConfig: AppRoute.router,
    );
  }
}
