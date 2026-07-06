class TripReportModel {
  final int deviceId;
  final String deviceName;
  final double distance;
  final double averageSpeed;
  final double maxSpeed;
  final double spentFuel;
  final double startOdometer;
  final double endOdometer;
  final DateTime startTime;
  final DateTime endTime;
  final double startLat;
  final double startLon;
  final double endLat;
  final double endLon;
  final String startAddress;
  final String endAddress;
  final int duration;
  final String driverUniqueId;
  final String driverName;

  TripReportModel({
    required this.deviceId,
    required this.deviceName,
    required this.distance,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.spentFuel,
    required this.startOdometer,
    required this.endOdometer,
    required this.startTime,
    required this.endTime,
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    required this.startAddress,
    required this.endAddress,
    required this.duration,
    required this.driverUniqueId,
    required this.driverName,
  });
}
