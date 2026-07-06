import 'package:get_it/get_it.dart';
import 'package:nusantara_gps/core/config/app_config.dart';
import 'package:nusantara_gps/core/service/dio_service.dart';
import 'package:nusantara_gps/core/service/storage/i_key_value_storage.dart';
import 'package:nusantara_gps/core/service/storage/shared_prefs_storage.dart';

import 'package:nusantara_gps/data/datasourse/i_auth_remote_data_source.dart';
import 'package:nusantara_gps/data/datasourse/i_location_iq_remote_data_source.dart';
import 'package:nusantara_gps/data/datasourse/i_vehicle_remote_data_source.dart';
import 'package:nusantara_gps/data/datasourse/i_lacak_tracking_remote_data_source.dart';
import 'package:nusantara_gps/data/datasourse/i_poi_remote_data_source.dart';   

import 'package:nusantara_gps/data/repositories/auth_repository_impl.dart';
import 'package:nusantara_gps/data/repositories/location_service_impl.dart';
import 'package:nusantara_gps/data/repositories/maps_repository_impl.dart';
import 'package:nusantara_gps/data/repositories/lacak_tracking_repository_impl.dart';
import 'package:nusantara_gps/data/repositories/vehicle_repository_impl.dart';
import 'package:nusantara_gps/data/repositories/alert_repository_impl.dart';
import 'package:nusantara_gps/data/repositories/poi_repository_impl.dart';   
import 'package:nusantara_gps/data/repositories/profile_repository_impl.dart'; 

import 'package:nusantara_gps/domain/event/data_invalidation_bus.dart';
import 'package:nusantara_gps/domain/interfaces/i_auth_repository.dart';
import 'package:nusantara_gps/domain/interfaces/i_location_service.dart';
import 'package:nusantara_gps/domain/interfaces/i_maps_repository.dart';
import 'package:nusantara_gps/domain/interfaces/i_tracking_repository.dart';
import 'package:nusantara_gps/domain/interfaces/i_vehicle_repository.dart';
import 'package:nusantara_gps/domain/interfaces/i_alert_repository.dart';
import 'package:nusantara_gps/domain/interfaces/i_poi_repository.dart';   
import 'package:nusantara_gps/domain/interfaces/i_profile_repository.dart';            
import 'package:nusantara_gps/domain/manager/session_manager.dart';

import 'package:nusantara_gps/presentation/screens/0_splash/splash_view_model.dart';
import 'package:nusantara_gps/presentation/screens/1_auth/login_view_model.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/maps_view_model.dart';
import 'package:nusantara_gps/presentation/screens/4_vehicle_list/vehicle_detail_view_model.dart';
import 'package:nusantara_gps/presentation/screens/4_vehicle_list/vehicle_list_view_model.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/poi_location_view_model.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/create/poi_create_view_model.dart'; // ← POI (ganti fav_location_create)
import 'package:nusantara_gps/presentation/screens/5_poi/update/poi_edit_view_model.dart';   // ← POI (ganti fav_location_edit)
import 'package:nusantara_gps/presentation/screens/6_setting/setting_view_model.dart';
import 'package:nusantara_gps/presentation/screens/7_route/route_history_view_model.dart';
import 'package:nusantara_gps/presentation/screens/8_trip/trip_report_view_model.dart';
import 'package:nusantara_gps/presentation/screens/9_follow_device/follow_device_view_model.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/geofence_view_model.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/edit/geofence_edit_view_model.dart';
import 'package:nusantara_gps/presentation/screens/10_geofence/create/geofence_create_view_model.dart';
import 'package:nusantara_gps/presentation/screens/11_alert/alert_view_model.dart';
import 'package:cookie_jar/cookie_jar.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<IKeyValueStorage>(() => SharedPrefsStorage());
  locator.registerLazySingleton<DataInvalidationBus>(() => DataInvalidationBus());
  locator.registerLazySingleton<SessionManager>(() => SessionManager(locator<IKeyValueStorage>()));
  locator.registerLazySingleton<CookieJar>(() => CookieJar());

  locator.registerFactoryParam<DioService, String, void>(
    (baseUrl, _) => DioService(
      baseUrl: baseUrl,
      sessionManager: locator<SessionManager>(),
      sharedCookieJar: locator<CookieJar>(),
    ),
  );

  // Data Sources 
  locator.registerLazySingleton<IAuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(locator<DioService>(param1: AppConfig.webBaseUrl)),
  );

  locator.registerLazySingleton<ILocationIqRemoteDataSource>(
    () => LocationIqRemoteDataSourceImpl(locator<DioService>(param1: AppConfig.locationIqBaseUrl)),
  );

  locator.registerLazySingleton<IVehicleRemoteDataSource>(
    () => VehicleRemoteDataSourceImpl(
      locator<DioService>(param1: AppConfig.apiBaseUrl),
      locator<IKeyValueStorage>(),
    ),
  );

  locator.registerLazySingleton<ILacakTrackingRemoteDataSource>(
    () => LacakTrackingRemoteDataSourceImpl(locator<DioService>(param1: AppConfig.apiBaseUrl)),
  );

  locator.registerLazySingleton<IPoiRemoteDataSource>(
    () => PoiRemoteDataSourceImpl(
      locator<DioService>(param1: AppConfig.apiBaseUrl),
    ),
  );

  // Repositories 
  locator.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(
      locator<IAuthRemoteDataSource>(),
      locator<IKeyValueStorage>(),
      locator<CookieJar>(),
    ),
  );

  locator.registerLazySingleton<ILocationService>(() => LocationServiceImpl());

  locator.registerLazySingleton<IVehicleRepository>(
    () => VehicleRepositoryImpl(
      locator<IVehicleRemoteDataSource>(),
    ),
  );

  locator.registerLazySingleton<IProfileRepository>(
    () => ProfileRepositoryImpl(
      locator<DioService>(param1: AppConfig.apiBaseUrl),
    ),
  );

  locator.registerLazySingleton<IMapsRepository>(
    () => MapsRepositoryImpl(locator<IVehicleRemoteDataSource>()),
  );

  locator.registerLazySingleton<ITrackingRepository>(
    () => LacakTrackingRepositoryImpl(
      locator<ILacakTrackingRemoteDataSource>(),
      locator<ILocationIqRemoteDataSource>(),
    ),
  );

  locator.registerLazySingleton<IAlertRepository>(
    () => AlertRepositoryImpl(
      locator<DioService>(param1: AppConfig.apiBaseUrl),
    ),
  );

  locator.registerLazySingleton<IPoiRepository>(
    () => PoiRepositoryImpl(
      locator<IPoiRemoteDataSource>(),
    ),
  );

  // ViewModels 
  locator.registerFactory(() => SplashViewModel(locator<IAuthRepository>()));

  locator.registerFactory(
    () => LoginViewModel(locator<IAuthRepository>(), locator<SessionManager>()),
  );

  locator.registerFactory(
    () => MapsViewModel(
      locator<ITrackingRepository>(),
      locator<IMapsRepository>(),
      locator<ILocationService>(),
      locator<IVehicleRepository>(),
    ),
  );

  locator.registerFactory(() => VehicleListViewModel(locator<IVehicleRepository>()));

  locator.registerFactory(
    () => VehicleDetailViewModel(
      locator<IVehicleRepository>(),
      locator<ITrackingRepository>(),
    ),
  );

  locator.registerFactory(
    () => SettingViewModel(
      locator<IAuthRepository>(), 
      locator<IKeyValueStorage>(),
      locator<IProfileRepository>(),
    ),
  );

  locator.registerFactory(() => RouteHistoryViewModel(locator<IVehicleRepository>()));

  locator.registerFactory(() => TripReportViewModel(locator<IVehicleRepository>()));

  locator.registerFactory(
    () => FollowDeviceViewModel(
      locator<ITrackingRepository>(),
      locator<ILocationService>(),
    ),
  );

  locator.registerFactory(() => GeofenceViewModel(
    locator<IVehicleRepository>(),
    locator<ITrackingRepository>(),
  ));

  locator.registerFactory(
    () => FavoriteLocationViewModel(
      locator<IPoiRepository>(),
      locator<DataInvalidationBus>(),
    ),
  );

  locator.registerFactory(
    () => PoiCreateViewModel(
      locator<IPoiRepository>(),
      locator<DataInvalidationBus>(),
    ),
  );

  locator.registerFactory(
    () => PoiEditViewModel(
      locator<IPoiRepository>(),
      locator<DataInvalidationBus>(),
    ),
  );

  locator.registerFactory(
    () => GeofenceCreateViewModel(
      locator<IVehicleRepository>(),
      locator<DataInvalidationBus>(),
    ),
  );

  locator.registerFactoryParam<GeofenceEditViewModel, int, void>(
    (id, _) => GeofenceEditViewModel(
      locator<IVehicleRepository>(),
      locator<DataInvalidationBus>(),
      geofenceId: id,
    ),
  );

  locator.registerFactory<AlertViewModel>(
    () => AlertViewModel(locator<IAlertRepository>()),
  );
}