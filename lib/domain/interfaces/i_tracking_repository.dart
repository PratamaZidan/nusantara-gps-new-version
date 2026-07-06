import 'package:nusantara_gps/data/models/device.dart';
import 'package:nusantara_gps/data/models/position.dart';

abstract class ITrackingRepository {
  Future<List<Device>> getTrackedDevices();
  Future<List<PositionModel>> getPosition({String? deviceId});
  Future<Device> getDeviceById({required int id});

  Future<String> getAddress({required double lat, required double lng});
}
