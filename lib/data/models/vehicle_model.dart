import 'package:nusantara_gps/core/app/constant.dart';

class Vehicle {
  final String id;
  final String brand;
  final String model;
  final String imageUrl;
  final String plateNumber;
  final VehicleStatus status;
  final String emei;
  final String gsm;

  Vehicle({
    required this.id,
    required this.brand,
    required this.plateNumber,
    required this.status,
    required this.emei,
    required this.gsm,
    required this.model,
    required this.imageUrl,
  });
}
