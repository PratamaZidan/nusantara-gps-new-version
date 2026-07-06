// ignore_for_file: prefer_collection_literals

import 'package:nusantara_gps/core/utils/inconsistent_value_extention.dart';
import 'package:nusantara_gps/data/models/trip_report_model.dart';

class TripReportDTO {
  int? statusCode;
  String? message;
  List<TripReportDTOData>? data;

  TripReportDTO({this.statusCode, this.message, this.data});

  TripReportDTO.fromJson(Map<String, dynamic> json) {
    statusCode = _toInt(json['statusCode']);
    message = json['message']?.toString();

    final raw = json['data'];
    if (raw is List) {
      data = raw
          .where((e) => e is Map)
          .map((e) => TripReportDTOData.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } else {
      data = <TripReportDTOData>[];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['statusCode'] = statusCode;
    data['message'] = message;
    data['data'] = this.data?.map((v) => v.toJson()).toList() ?? [];
    return data;
  }
}

class TripReportDTOData {
  int? deviceId;
  String? deviceName;
  num? distance;
  num? averageSpeed;
  num? maxSpeed;
  num? spentFuel;
  num? startOdometer;
  num? endOdometer;
  String? startTime;
  String? endTime;
  int? startPositionId;
  int? endPositionId;
  num? startLat;
  num? startLon;
  num? endLat;
  num? endLon;
  String? startAddress;
  String? endAddress;
  int? duration;
  String? driverUniqueId;
  String? driverName;

  TripReportDTOData({
    this.deviceId,
    this.deviceName,
    this.distance,
    this.averageSpeed,
    this.maxSpeed,
    this.spentFuel,
    this.startOdometer,
    this.endOdometer,
    this.startTime,
    this.endTime,
    this.startPositionId,
    this.endPositionId,
    this.startLat,
    this.startLon,
    this.endLat,
    this.endLon,
    this.startAddress,
    this.endAddress,
    this.duration,
    this.driverUniqueId,
    this.driverName,
  });

  TripReportDTOData.fromJson(Map<String, dynamic> json) {
    deviceId = _toInt(json['deviceId']);
    deviceName = json['deviceName']?.toString();

    distance = _toNum(json['distance']);
    averageSpeed = _toNum(json['averageSpeed']);
    maxSpeed = _toNum(json['maxSpeed']);
    spentFuel = _toNum(json['spentFuel']);
    startOdometer = _toNum(json['startOdometer']);
    endOdometer = _toNum(json['endOdometer']);

    startTime = json['startTime']?.toString();
    endTime = json['endTime']?.toString();

    startPositionId = _toInt(json['startPositionId']);
    endPositionId = _toInt(json['endPositionId']);

    startLat = _toNum(json['startLat']);
    startLon = _toNum(json['startLon']);
    endLat = _toNum(json['endLat']);
    endLon = _toNum(json['endLon']);

    startAddress = json['startAddress']?.toString();
    endAddress = json['endAddress']?.toString();

    duration = _toInt(json['duration']);
    driverUniqueId = json['driverUniqueId']?.toString();
    driverName = json['driverName']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['deviceId'] = deviceId;
    data['deviceName'] = deviceName;
    data['distance'] = distance;
    data['averageSpeed'] = averageSpeed;
    data['maxSpeed'] = maxSpeed;
    data['spentFuel'] = spentFuel;
    data['startOdometer'] = startOdometer;
    data['endOdometer'] = endOdometer;
    data['startTime'] = startTime;
    data['endTime'] = endTime;
    data['startPositionId'] = startPositionId;
    data['endPositionId'] = endPositionId;
    data['startLat'] = startLat;
    data['startLon'] = startLon;
    data['endLat'] = endLat;
    data['endLon'] = endLon;
    data['startAddress'] = startAddress;
    data['endAddress'] = endAddress;
    data['duration'] = duration;
    data['driverUniqueId'] = driverUniqueId;
    data['driverName'] = driverName;
    return data;
  }

  /// ✅ FIX UTAMA: jadikan member method (bukan extension),
  /// supaya selalu bisa dipanggil e.toEntity() di repository.
  TripReportModel toEntity() {
    return TripReportModel(
      deviceId: deviceId ?? 0,
      deviceName: deviceName ?? '',
      distance: distance.toDoubleSafe(),
      averageSpeed: normalizeToDouble(averageSpeed?.knotsToKmPerHour()),
      maxSpeed: normalizeToDouble(maxSpeed?.knotsToKmPerHour()),
      spentFuel: spentFuel.toDoubleSafe(),
      startOdometer: normalizeToDouble(startOdometer),
      endOdometer: normalizeToDouble(endOdometer),
      startTime: _parseDate(startTime),
      endTime: _parseDate(endTime),
      startLat: normalizeToDouble(startLat),
      startLon: normalizeToDouble(startLon),
      endLat: normalizeToDouble(endLat),
      endLon: normalizeToDouble(endLon),
      startAddress: startAddress ?? 'Alamat tidak diketahui',
      endAddress: endAddress ?? 'Alamat tidak diketahui',
      duration: duration ?? 0,
      driverUniqueId: driverUniqueId ?? 'unknown',
      driverName: driverName ?? 'Unknown Driver',
    );
  }
}

DateTime _parseDate(String? value) {
  if (value == null || value.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

num? _toNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  // handle "162,439.5" style
  final s = v.toString().replaceAll(',', '');
  return num.tryParse(s);
}