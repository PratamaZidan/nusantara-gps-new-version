import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/core/utils/distance_util.dart';
import 'package:nusantara_gps/data/models/detail_vehicle.dart';
import 'package:nusantara_gps/core/utils/distance_util.dart';

class LacakDetailVehicleMapper {
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return DateTime.now();
    }

    final raw = value.toString().trim().replaceFirst(' ', 'T');
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  static String _pickString(Map<String, dynamic> m, List<String> keys) {
    for (final key in keys) {
      final value = m[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '-';
  }

  static String _deviceName(Map<String, dynamic> m) {
    return (m['device'] ?? m['name'] ?? m['title'] ?? '').toString().trim();
  }

  static String _extractPlateNumber(String text) {
    if (text.trim().isEmpty) return '-';

    final match = RegExp(
      r'\b([A-Z]{1,2}\s?\d{1,4}\s?[A-Z]{1,3})\b',
      caseSensitive: false,
    ).firstMatch(text.toUpperCase());

    if (match != null) {
      return match.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    return '-';
  }

  static String _extractVehicleBrand(Map<String, dynamic> m) {
    final direct = _pickString(m, [
      'vehicle_brand',
      'brand',
      'merk',
      'vehiclebrand',
      'vehicleBrand',
      'nama_kendaraan',
    ]);

    if (direct != '-') return direct;

    final device = _deviceName(m);
    if (device.isEmpty) return '-';

    final plate = _extractPlateNumber(device);
    if (plate == '-') {
      return device;
    }

    final cleaned = device.replaceFirst(plate, '').trim();
    return cleaned.isNotEmpty ? cleaned : '-';
  }

  static VehicleStatus _mapStatus(Map<String, dynamic> m) {
    final icon = (m['icon'] ?? m['marker']?['icon'] ?? '')
        .toString()
        .toLowerCase();

    final engine = (m['engine'] ?? m['marker']?['engine'] ?? '0').toString();

    if (icon.contains('_on')) return VehicleStatus.on;
    if (icon.contains('_off')) return VehicleStatus.off;
    if (icon.contains('standby')) return VehicleStatus.standby;

    if (icon.contains('down') ||
        icon.contains('lost') ||
        icon.contains('nodata') ||
        icon.contains('offline')) {
      return VehicleStatus.down;
    }

    return engine == '1' ? VehicleStatus.on : VehicleStatus.off;
  }

  static DetailVehicle fromListDevicesItem(Map<String, dynamic> m) {
    final deviceName = _deviceName(m);

    print('[DETAIL_RAW_ITEM] $m');
    print(
      '[DETAIL_PARSE] device=$deviceName '
      'brand=${_extractVehicleBrand(m)} '
      'plate=${_extractPlateNumber(deviceName)}',
    );

    return DetailVehicle(
      uuid: (m['uuid'] ?? m['id'] ?? m['deviceid'] ?? '').toString(),
      vehicleId: int.tryParse(
            (m['id'] ?? m['vehicleid'] ?? m['deviceid'] ?? '0').toString(),
          ) ??
          0,
      name: deviceName.isNotEmpty ? deviceName : '-',
      vehicleBrand: _extractVehicleBrand(m),
      model: _pickString(m, [
        'model',
      ]),
      platNumber: (() {
        final direct = _pickString(m, [
          'plat_number',
          'plate_number',
          'police_number',
          'nopol',
          'platnomor',
          'plat_no',
          'plate_no',
        ]);

        if (direct != '-') return direct;

        return _extractPlateNumber(deviceName);
      })(),
      emei: _pickString(m, [
        'deviceid',
        'imei',
        'emei',
      ]),
      gsm: _pickString(m, [
        'msisdn',
        'gsm',
      ]),
      status: _mapStatus(m),
      totalDistance: normalizeMileageToKm(m['mileage'] ?? m['total_distance']),
      speed: _parseDouble(m['speed']),
      lat: _parseDouble(m['lat'] ?? m['latitude']),
      lng: _parseDouble(m['lng'] ?? m['longitude']),
      lastUpdate: _parseDate(
        m['lastupdate'] ?? m['last_update'] ?? m['timestamp1'] ?? m['timestamp'],
      ),
    );
  }
}