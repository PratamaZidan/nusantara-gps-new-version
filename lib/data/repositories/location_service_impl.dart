import 'package:geolocator/geolocator.dart';
import 'package:nusantara_gps/domain/interfaces/i_location_service.dart';

class LocationServiceImpl implements ILocationService {
  @override
  Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 3),
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  @override
  Future<bool> requestPermissionAndCheckService() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return false;
    }
    return true;
  }
}
