import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/utils/inconsistent_value_extention.dart';
import 'package:nusantara_gps/data/models/detail_vehicle.dart';

class DetailVehicleDto {
  int? statusCode;
  String? message;
  Data? data;

  DetailVehicleDto({this.statusCode, this.message, this.data});

  DetailVehicleDto.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? id;
  String? vehicleTypeId;
  String? fuelTypeId;
  int? traccarId;
  String? vehicleBrand;
  String? model;
  String? policeNumber;
  String? color;
  String? vin;
  int? condition;
  String? engineNumber;
  String? machineCapacity;
  String? imei;
  String? gsm;
  List<String>? picture;
  int? odometer;
  String? lastStatusGps;
  String? estDistanceFuel;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  Traccar? traccar;
  List<DetailPosition>? position;

  Data({
    this.id,
    this.vehicleTypeId,
    this.fuelTypeId,
    this.traccarId,
    this.vehicleBrand,
    this.model,
    this.policeNumber,
    this.color,
    this.vin,
    this.condition,
    this.engineNumber,
    this.machineCapacity,
    this.imei,
    this.gsm,
    this.picture,
    this.odometer,
    this.lastStatusGps,
    this.estDistanceFuel,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.traccar,
    this.position,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vehicleTypeId = json['vehicle_type_id'];
    fuelTypeId = json['fuel_type_id'];
    traccarId = json['traccar_id'];
    vehicleBrand = json['vehicle_brand'];
    model = json['model'];
    policeNumber = json['police_number'];
    color = json['color'];
    vin = json['vin'];
    condition = json['condition'];
    engineNumber = json['engine_number'];
    machineCapacity = json['machine_capacity'];
    imei = json['imei'];
    gsm = json['gsm'];
    final rawPicture = json['picture'];
    if (rawPicture is List) {
      picture = rawPicture.map((e) => e.toString()).toList();
    } else {
      picture = <String>[];
    }
    odometer = json['odometer'];
    lastStatusGps = json['last_status_gps'];
    estDistanceFuel = json['est_distance_fuel'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    traccar = json['traccar'] != null
        ? Traccar.fromJson(json['traccar'])
        : null;
    if (json['position'] != null) {
      position = <DetailPosition>[];
      json['position'].forEach((v) {
        position!.add(DetailPosition.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['vehicle_type_id'] = vehicleTypeId;
    data['fuel_type_id'] = fuelTypeId;
    data['traccar_id'] = traccarId;
    data['vehicle_brand'] = vehicleBrand;
    data['model'] = model;
    data['police_number'] = policeNumber;
    data['color'] = color;
    data['vin'] = vin;
    data['condition'] = condition;
    data['engine_number'] = engineNumber;
    data['machine_capacity'] = machineCapacity;
    data['imei'] = imei;
    data['gsm'] = gsm;
    data['picture'] = picture;
    data['odometer'] = odometer;
    data['last_status_gps'] = lastStatusGps;
    data['est_distance_fuel'] = estDistanceFuel;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    if (traccar != null) {
      data['traccar'] = traccar!.toJson();
    }
    if (position != null) {
      data['position'] = position!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Traccar {
  int? id;
  // TraccarAttributes? attributes;
  int? groupId;
  int? calendarId;
  String? name;
  String? uniqueId;
  String? status;
  String? lastUpdate;
  int? positionId;
  String? phone;
  String? model;
  Null contact;
  Null category;
  bool? disabled;
  Null expirationTime;

  Traccar({
    this.id,
    // this.attributes,
    this.groupId,
    this.calendarId,
    this.name,
    this.uniqueId,
    this.status,
    this.lastUpdate,
    this.positionId,
    this.phone,
    this.model,
    this.contact,
    this.category,
    this.disabled,
    this.expirationTime,
  });

  Traccar.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    // attributes = json['attributes'] != null
    //     ? TraccarAttributes.fromJson(json['attributes'])
    //     : null;
    groupId = json['groupId'];
    calendarId = json['calendarId'];
    name = json['name'];
    uniqueId = json['uniqueId'];
    status = json['status'];
    lastUpdate = json['lastUpdate'];
    positionId = json['positionId'];
    phone = json['phone'];
    model = json['model'];
    contact = json['contact'];
    category = json['category'];
    disabled = json['disabled'];
    expirationTime = json['expirationTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    // if (attributes != null) {
    //   data['attributes'] = attributes!.toJson();
    // }
    data['groupId'] = groupId;
    data['calendarId'] = calendarId;
    data['name'] = name;
    data['uniqueId'] = uniqueId;
    data['status'] = status;
    data['lastUpdate'] = lastUpdate;
    data['positionId'] = positionId;
    data['phone'] = phone;
    data['model'] = model;
    data['contact'] = contact;
    data['category'] = category;
    data['disabled'] = disabled;
    data['expirationTime'] = expirationTime;
    return data;
  }
}

class TraccarAttributes {
  String? activeMapStyles;
  bool? mapFollow;
  String? mapDirection;
  String? mapLiveRoutes;
  String? deviceSecondary;
  String? positionItems;

  TraccarAttributes({
    this.activeMapStyles,
    this.mapFollow,
    this.mapDirection,
    this.mapLiveRoutes,
    this.deviceSecondary,
    this.positionItems,
  });

  TraccarAttributes.fromJson(Map<String, dynamic> json) {
    activeMapStyles = json['activeMapStyles'];
    mapFollow = json['mapFollow'];
    mapDirection = json['mapDirection'];
    mapLiveRoutes = json['mapLiveRoutes'];
    deviceSecondary = json['deviceSecondary'];
    positionItems = json['positionItems'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['activeMapStyles'] = activeMapStyles;
    data['mapFollow'] = mapFollow;
    data['mapDirection'] = mapDirection;
    data['mapLiveRoutes'] = mapLiveRoutes;
    data['deviceSecondary'] = deviceSecondary;
    data['positionItems'] = positionItems;
    return data;
  }
}

class DetailPosition {
  int? id;
  VehiclePositionAttributes? attributes;
  int? deviceId;
  String? protocol;
  String? serverTime;
  String? deviceTime;
  String? fixTime;
  bool? valid;
  num? latitude;
  num? longitude;
  num? altitude;
  num? speed;
  num? course;
  Null address;
  num? accuracy;
  NetworkData? network;
  Null geofenceIds;

  DetailPosition({
    this.id,
    this.attributes,
    this.deviceId,
    this.protocol,
    this.serverTime,
    this.deviceTime,
    this.fixTime,
    this.valid,
    this.latitude,
    this.longitude,
    this.altitude,
    this.speed,
    this.course,
    this.address,
    this.accuracy,
    this.network,
    this.geofenceIds,
  });

  DetailPosition.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    attributes = json['attributes'] != null
        ? VehiclePositionAttributes.fromJson(json['attributes'])
        : null;
    deviceId = json['deviceId'];
    protocol = json['protocol'];
    serverTime = json['serverTime'];
    deviceTime = json['deviceTime'];
    fixTime = json['fixTime'];
    valid = json['valid'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    altitude = json['altitude'];
    speed = json['speed'];
    course = json['course'];
    address = json['address'];
    accuracy = json['accuracy'];
    network = json['network'] != null
        ? NetworkData.fromJson(json['network'])
        : null;
    geofenceIds = json['geofenceIds'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (attributes != null) {
      data['attributes'] = attributes!.toJson();
    }
    data['deviceId'] = deviceId;
    data['protocol'] = protocol;
    data['serverTime'] = serverTime;
    data['deviceTime'] = deviceTime;
    data['fixTime'] = fixTime;
    data['valid'] = valid;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['altitude'] = altitude;
    data['speed'] = speed;
    data['course'] = course;
    data['address'] = address;
    data['accuracy'] = accuracy;
    data['network'] = network;
    data['geofenceIds'] = geofenceIds;
    return data;
  }
}

class VehiclePositionAttributes {
  int? type;
  int? status;
  bool? ignition;
  bool? charge;
  bool? blocked;
  int? batteryLevel;
  int? rssi;
  num? distance;
  num? totalDistance;
  bool? motion;
  int? hours;

  VehiclePositionAttributes({
    this.type,
    this.status,
    this.ignition,
    this.charge,
    this.blocked,
    this.batteryLevel,
    this.rssi,
    this.distance,
    this.totalDistance,
    this.motion,
    this.hours,
  });

  VehiclePositionAttributes.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    status = json['status'];
    ignition = json['ignition'];
    charge = json['charge'];
    blocked = json['blocked'];
    batteryLevel = json['batteryLevel'];
    rssi = json['rssi'];
    distance = json['distance'];
    totalDistance = json['totalDistance'];
    motion = json['motion'];
    hours = json['hours'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['status'] = status;
    data['ignition'] = ignition;
    data['charge'] = charge;
    data['blocked'] = blocked;
    data['batteryLevel'] = batteryLevel;
    data['rssi'] = rssi;
    data['distance'] = distance;
    data['totalDistance'] = totalDistance;
    data['motion'] = motion;
    data['hours'] = hours;
    return data;
  }
}

extension DetailVehicleMapper on DetailVehicleDto {
  DetailVehicle toEntity() {
    final firstPos = (data?.position != null && data!.position!.isNotEmpty)
        ? data!.position!.first
        : null;

    final totalDistance = firstPos?.attributes?.totalDistance.toDoubleSafe() ?? 0.0;
    final speed = normalizeToDouble(firstPos?.speed?.knotsToKmPerHour());
    final lat = firstPos?.latitude.toDoubleSafe() ?? 0.0;
    final lng = firstPos?.longitude.toDoubleSafe() ?? 0.0;

    final statusStr = (data?.traccar?.status ?? data?.lastStatusGps ?? '').toString().toLowerCase();
    final vehicleStatus = statusStr == 'online' ? VehicleStatus.on : VehicleStatus.off;

    return DetailVehicle(
      uuid: data?.id ?? '-',
      vehicleId: data?.traccarId ?? 0,
      vehicleBrand: data?.vehicleBrand ?? '-',
      platNumber: data?.policeNumber ?? '-',
      emei: data?.imei ?? '-',
      gsm: data?.gsm ?? '-',
      status: vehicleStatus,
      totalDistance: totalDistance,
      speed: speed,
      lat: lat,
      lng: lng,
      name: data?.traccar?.name ?? data?.model ?? 'Unknown Name',
      model: data?.model ?? 'Unknown Model',
      lastUpdate: DateTime.now(),
    );
  }
}

class NetworkData {
  String? radioType;
  bool? considerIp;
  List<CellTowers>? cellTowers;

  NetworkData({this.radioType, this.considerIp, this.cellTowers});

  NetworkData.fromJson(Map<String, dynamic> json) {
    radioType = json['radioType'];
    considerIp = json['considerIp'];
    if (json['cellTowers'] != null) {
      cellTowers = <CellTowers>[];
      json['cellTowers'].forEach((v) {
        cellTowers!.add(CellTowers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['radioType'] = radioType;
    data['considerIp'] = considerIp;
    if (cellTowers != null) {
      data['cellTowers'] = cellTowers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CellTowers {
  int? cellId;
  int? locationAreaCode;
  int? mobileCountryCode;
  int? mobileNetworkCode;

  CellTowers({
    this.cellId,
    this.locationAreaCode,
    this.mobileCountryCode,
    this.mobileNetworkCode,
  });

  CellTowers.fromJson(Map<String, dynamic> json) {
    cellId = json['cellId'];
    locationAreaCode = json['locationAreaCode'];
    mobileCountryCode = json['mobileCountryCode'];
    mobileNetworkCode = json['mobileNetworkCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cellId'] = cellId;
    data['locationAreaCode'] = locationAreaCode;
    data['mobileCountryCode'] = mobileCountryCode;
    data['mobileNetworkCode'] = mobileNetworkCode;
    return data;
  }
}
