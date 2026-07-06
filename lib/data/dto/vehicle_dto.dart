import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/data/models/vehicle_model.dart';

class VehicleDto {
  int? statusCode;
  String? message;
  int? totalPages;
  int? pageNo;
  int? pageSize;
  int? totalRecords;
  String? nextPage;
  String? previousPage;
  List<VehicleData>? data;

  VehicleDto({
    this.statusCode,
    this.message,
    this.totalPages,
    this.pageNo,
    this.pageSize,
    this.totalRecords,
    this.nextPage,
    this.previousPage,
    this.data,
  });

  VehicleDto.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    totalPages = json['totalPages'];
    pageNo = json['pageNo'];
    pageSize = json['pageSize'];
    totalRecords = json['totalRecords'];
    nextPage = json['nextPage'];
    previousPage = json['previousPage'];

    final raw = json['data'];
    if (raw is List) {
      data = raw.map((v) => VehicleData.fromJson((v as Map).cast<String, dynamic>())).toList();
    } else {
      data = <VehicleData>[];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['message'] = message;
    data['totalPages'] = totalPages;
    data['pageNo'] = pageNo;
    data['pageSize'] = pageSize;
    data['totalRecords'] = totalRecords;
    data['nextPage'] = nextPage;
    data['previousPage'] = previousPage;
    data['data'] = this.data?.map((v) => v.toJson()).toList() ?? [];
    return data;
  }
}

class VehicleData {
  String? id;
  String? userId;
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
  String? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  VehicleData({
    this.id,
    this.userId,
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
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  VehicleData.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    userId = json['user_id']?.toString();
    vehicleTypeId = json['vehicle_type_id']?.toString();
    fuelTypeId = json['fuel_type_id']?.toString();

    final rawTraccar = json['traccar_id'];
    traccarId = rawTraccar is int ? rawTraccar : int.tryParse(rawTraccar?.toString() ?? '');

    vehicleBrand = json['vehicle_brand']?.toString();
    model = json['model']?.toString();
    policeNumber = json['police_number']?.toString();
    color = json['color']?.toString();
    vin = json['vin']?.toString();

    final rawCondition = json['condition'];
    condition = rawCondition is int ? rawCondition : int.tryParse(rawCondition?.toString() ?? '');

    engineNumber = json['engine_number']?.toString();
    machineCapacity = json['machine_capacity']?.toString();
    imei = json['imei']?.toString();
    gsm = json['gsm']?.toString();

    // picture aman walau null / kosong / bukan List<String>
    final rawPicture = json['picture'];
    if (rawPicture is List) {
      picture = rawPicture.map((e) => e.toString()).toList();
    } else {
      picture = <String>[]; // default kosong (tidak null)
    }

    final rawOdo = json['odometer'];
    odometer = rawOdo is int ? rawOdo : int.tryParse(rawOdo?.toString() ?? '');

    status = json['status']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    deletedAt = json['deleted_at']?.toString();
  }

  // KEEP METHOD INI DI CLASS (JANGAN HAPUS)
  Vehicle toEntity() {
    final pics = picture ?? const <String>[];
    final imageUrl = pics.isNotEmpty
        ? pics.first
        : 'https://img.freepik.com/free-photo/view-3d-car_23-2150796894.jpg?semt=ais_se_enriched&w=740&q=80';

    return Vehicle(
      id: id ?? 'unknown',
      brand: vehicleBrand ?? 'unknown brand',
      imageUrl: imageUrl,
      plateNumber: policeNumber ?? 'unknown plate number',
      status: status == 'online' ? VehicleStatus.on : VehicleStatus.off,
      emei: imei ?? '-',
      gsm: gsm ?? '-',
      model: model ?? 'unknown model',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
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
    data['picture'] = picture ?? [];
    data['odometer'] = odometer;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    return data;
  }
}