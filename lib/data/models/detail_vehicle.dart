import 'package:nusantara_gps/core/app/constant.dart';

class DetailVehicle {
  final String uuid;
  final int vehicleId;
  final String name;
  final String vehicleBrand;
  final String model;
  final String platNumber;
  final String emei;
  final String gsm;
  final VehicleStatus status;
  final double totalDistance;
  final double speed;
  final double lat;
  final double lng;
  final DateTime lastUpdate;

  const DetailVehicle({
    required this.uuid,
    required this.vehicleId,
    required this.name,
    required this.vehicleBrand,
    required this.model,
    required this.platNumber,
    required this.emei,
    required this.gsm,
    required this.status,
    required this.totalDistance,
    required this.speed,
    required this.lat,
    required this.lng,
    required this.lastUpdate,
  });
}
