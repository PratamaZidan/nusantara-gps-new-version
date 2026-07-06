import 'package:nusantara_gps/core/app/constant.dart';

class PositionModel {
  final int deviceId;
  final double latitude;
  final double longitude;
  final double course;
  final int sat;
  final String address;
  final VehicleStatus status;
  final double speed;
  final double totalDistance;
  final int? voltageLevel;
  final int? batteryPercent;
  final String deviceTime;
  final DateTime fixTime;
  final DateTime serverTimeUTC;

  PositionModel({
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.course,
    required this.sat,
    required this.address,
    required this.status,
    required this.speed,
    required this.totalDistance,
    this.batteryPercent,
    this.voltageLevel,
    required this.deviceTime,
    required this.fixTime,
    required this.serverTimeUTC,
  });
}
