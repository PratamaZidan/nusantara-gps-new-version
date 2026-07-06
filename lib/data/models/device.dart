import 'package:nusantara_gps/core/app/constant.dart';

class Device {
  final int id;
  final String name;
  final String uniqueId;
  final VehicleStatus status;
  final String phone;
  final String model;
  final int? positionId;
  final DateTime lastUpdate;
  final double long;
  final double lat;
  final double speed;
  final double direction;
  final double battery;

  const Device({
    required this.id,
    required this.name,
    required this.uniqueId,
    required this.status,
    required this.phone,
    required this.model,
    required this.positionId,
    required this.lastUpdate,
    required this.long,
    required this.lat,
    required this.speed,
    required this.direction,
    required this.battery,
  });
}
