import 'package:go_router/go_router.dart';
import 'package:nusantara_gps/core/di/dependency_injection.dart';
import 'package:nusantara_gps/domain/entities/auth_status.dart';
import 'package:nusantara_gps/domain/manager/session_manager.dart';
import 'package:nusantara_gps/data/models/poi_model.dart';
import 'package:nusantara_gps/presentation/screens/0_splash/splash_screen.dart';
import 'package:nusantara_gps/presentation/screens/0_splash/splash_view_model.dart';
import 'package:nusantara_gps/presentation/screens/1_auth/login_screen.dart';
import 'package:nusantara_gps/presentation/screens/1_auth/login_view_model.dart';
import 'package:nusantara_gps/presentation/screens/2_main_shell/main_shell_screen.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/maps_screen.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/maps_view_model.dart';
import 'package:nusantara_gps/presentation/screens/4_vehicle_list/vehicle_detail_screen.dart';
import 'package:nusantara_gps/presentation/screens/4_vehicle_list/vehicle_list_screen.dart';
import 'package:nusantara_gps/presentation/screens/4_vehicle_list/vehicle_list_view_model.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/create/poi_create_screen.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/create/poi_create_view_model.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/update/poi_edit_screen.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/update/poi_edit_view_model.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/poi_location_screen.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/poi_location_view_model.dart';
import 'package:nusantara_gps/presentation/screens/6_setting/setting_screen.dart';
import 'package:nusantara_gps/presentation/screens/6_setting/setting_view_model.dart';
import 'package:nusantara_gps/presentation/screens/7_route/route_history_screen.dart';
import 'package:nusantara_gps/presentation/screens/7_route/route_history_view_model.dart';
import 'package:nusantara_gps/presentation/screens/8_trip/trip_report_screen.dart';
import 'package:nusantara_gps/presentation/screens/8_trip/trip_report_view_model.dart';
import 'package:nusantara_gps/presentation/screens/9_follow_device/follow_device_screen.dart';
import 'package:nusantara_gps/presentation/screens/9_follow_device/follow_device_view_model.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/geofence_screen.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/geofence_view_model.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/create/geofence_create_screen.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/create/geofence_create_view_model.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/edit/geofence_edit_screen.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/edit/geofence_edit_view_model.dart';
import 'package:nusantara_gps/presentation/screens/11_alert/alert_screen.dart';
import 'package:nusantara_gps/presentation/screens/11_alert/alert_view_model.dart';
import 'package:provider/provider.dart';

class AppRoute {
  static final router = GoRouter(
    refreshListenable: locator<SessionManager>().authState,
    initialLocation: "/splash",
    redirect: (context, state) {
      final status = locator<SessionManager>().authState.value;
      final location = state.matchedLocation;
      if (status == AuthStatus.unauthenticated && location != '/login') {
        return '/login';
      }
      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => locator<SplashViewModel>(),
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => locator<LoginViewModel>(),
          child: const LoginScreen(),
        ),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/maps',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) => locator<MapsViewModel>()
                    ..initMap()
                    ..init()
                    ..loadInitial(),
                  child: const MapsScreen(),
                ),
              ),
            ],
          ),

          // vehicles
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/vehicles',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) => locator<VehicleListViewModel>(),
                  child: const VehicleListScreen(),
                ),
              ),
            ],
          ),

          // about
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorite-location',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) =>
                      locator<FavoriteLocationViewModel>()..ensureInitialized(),
                  child: const FavoriteLocationScreen(),
                ),
              ),
            ],
          ),

          // geofence
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/geofence',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) => locator<GeofenceViewModel>(),
                  child: const GeofenceScreen(),
                ),
              ),
            ],
          ),

          // profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/setting',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) => locator<SettingViewModel>()..load(),
                  child: const SettingScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/vehicle-detail/:uuid',
        name: 'vehicle-detail-id',
        builder: (context, state) {
          final uuid = state.pathParameters['uuid']!;
          return VehicleDetailScreen(vehicleId: uuid);
        },
      ),
      GoRoute(
        path: '/route-history/:id',
        name: 'route-history',
        builder: (context, state) {
          // --- Parse deviceId ---
          final idString = state.pathParameters['id']!;
          final deviceId = int.tryParse(idString);
          if (deviceId == null) {
            throw Exception("Invalid vehicle id: $idString");
          }

          final startString = state.uri.queryParameters['start'];
          final endString = state.uri.queryParameters['end'];

          DateTime? startDate;
          DateTime? endDate;

          if (startString != null) {
            startDate = DateTime.tryParse(startString);
          }
          if (endString != null) {
            endDate = DateTime.tryParse(endString);
          }
          return ChangeNotifierProvider(
            create: (_) {
              final vm = locator<RouteHistoryViewModel>();
              vm.loadMapStyle();
              vm.loadRouteHistory(
                deviceId: deviceId,
                startDate: startDate,
                endDate: endDate,
              );
              return vm;
            },
            child: RouteHistoryScreen(vehicleId: deviceId),
          );
        },
      ),
      GoRoute(
        path: '/trip-report/:id',
        name: 'trip-report',

        builder: (context, state) {
          final idString = state.pathParameters['id']!;
          final id = int.tryParse(idString);
          if (id == null) {
            throw Exception("Invalid vehicle id: $idString");
          }
          return ChangeNotifierProvider(
            create: (_) => locator<TripReportViewModel>()..loadTripReport(id),
            child: TripReportScreen(deviceId: id),
          );
        },
      ),
      GoRoute(
        path: '/follow-device/:id',
        name: 'follow-device',
        builder: (context, state) {
          final idString = state.pathParameters['id']!;
          final id = int.tryParse(idString);
          if (id == null) {
            throw Exception("Invalid vehicle id: $idString");
          }
          return ChangeNotifierProvider(
            create: (_) => locator<FollowDeviceViewModel>()
              ..initialDevice(id)
              ..startPolling(id)
              ..init(),
            child: FollowDeviceScreen(deviceId: id),
          );
        },
      ),

      GoRoute(
        path: '/geofence',
        builder: (context, state) {
          return ChangeNotifierProvider(
            create: (_) => locator<GeofenceViewModel>(),
            child: const GeofenceScreen(),
          );
        },
      ),

      GoRoute(
        path: '/geofence/create',
        name: 'geofence-create',
        builder: (context, state) {
          return ChangeNotifierProvider(
            create: (_) => locator<GeofenceCreateViewModel>(),
            child: const GeofenceCreateScreen(),
          );
        },
      ),

      GoRoute(
        path: '/geofence-edit/:id',
        name: 'geofence-edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ChangeNotifierProvider(
            create: (_) => locator<GeofenceEditViewModel>(param1: id)..loadGeofence(),
            child: GeofenceEditScreen(geofenceId: id),
          );
        },
      ),

      GoRoute(
        path: '/poi/edit/:id',
        name: 'poi-edit',
        builder: (context, state) {
          final poi = state.extra as PoiModel;
          return ChangeNotifierProvider(
            create: (_) =>
                locator<PoiEditViewModel>()..initFromPoi(poi),
            child: const PoiEditScreen(),
          );
        },
      ),

      GoRoute(
        path: '/poi/create',
        name: 'poi-create',
        builder: (context, state) {
          final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '') ?? 0.0;
          final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '') ?? 0.0;
          return ChangeNotifierProvider(
            create: (_) => locator<PoiCreateViewModel>()..setInitialLatLng(lat, lng),
            child: PoiCreateScreen(lat: lat, lng: lng),
          );
        },
      ),

      GoRoute(
        path: '/alert',
        builder: (context, state) {
          return ChangeNotifierProvider(
            create: (_) => locator<AlertViewModel>()..loadAlerts(),
            child: const AlertScreen(),
          );
        },
      ),
    ],
  );
}
