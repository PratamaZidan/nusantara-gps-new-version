import 'package:geolocator/geolocator.dart';

abstract class ILocationService {
  Future<bool> requestPermissionAndCheckService();
  Stream<Position> getPositionStream(); // DetailPosition from GeoLocator
}
