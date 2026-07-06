import 'dart:convert';

import 'package:nusantara_gps/data/dto/vehicle_dto.dart';

class LacakVehicleMapper {
  static VehicleDto listDevicesToVehicleDto(
    dynamic raw, {
    required String searchQuery,
    required int page,
  }) {
    final data = _normalizeJson(raw);

    final List root = (data is Map && data['root'] is List) ? (data['root'] as List) : const [];

    final q = searchQuery.trim().toLowerCase();
    final filtered = root.whereType<Map>().where((m) {
      if (q.isEmpty) return true;
      final deviceName = (m['device'] ?? '').toString().toLowerCase();
      final deviceId = (m['deviceid'] ?? '').toString().toLowerCase();
      return deviceName.contains(q) || deviceId.contains(q);
    }).toList();

    // DEDUPLIKASI BERDASARKAN ID YANG UNIK
    final Set<String> seenIds = {};
    final deduplicated = <Map>[];
    
    for (final item in filtered) {
      final id = (item['id'] ?? '').toString();
      
      if (id.isNotEmpty) {
        // Jika ada ID, gunakan ID sebagai unique key
        if (!seenIds.contains(id)) {
          seenIds.add(id);
          deduplicated.add(item);
        }
      } else {
        // Jika tidak ada ID, gunakan kombinasi device + deviceid sebagai unique key
        final deviceKey = '${item['device']}|${item['deviceid']}';
        if (!seenIds.contains(deviceKey)) {
          seenIds.add(deviceKey);
          deduplicated.add(item);
        }
      }
    }

    const perPage = 10;
    final start = (page - 1) * perPage;
    final end = start + perPage;
    final paged = (start >= deduplicated.length)
        ? <Map>[]
        : deduplicated.sublist(start, end > deduplicated.length ? deduplicated.length : end);

    final vehicles = paged.map((m) => _lacakDeviceToVehicleData(m)).toList();

    return VehicleDto(
      statusCode: 200,
      message: 'OK',
      pageNo: page,
      pageSize: perPage,
      totalRecords: deduplicated.length, 
      totalPages: (deduplicated.length / perPage).ceil(),
      data: vehicles,
    );
  }

  static dynamic _normalizeJson(dynamic raw) {
    if (raw is String) {
      try {
        return jsonDecode(raw);
      } catch (_) {
        return raw;
      }
    }
    return raw;
  }

  static VehicleData _lacakDeviceToVehicleData(Map m) {
    final deviceName = (m['device'] ?? '').toString();
    final deviceId = (m['deviceid'] ?? '').toString();

    // deviceid kadang ada spasi (contoh: "3537010933 42794")
    final imei = deviceId.replaceAll(' ', '');

    final plate = _extractPlate(deviceName);
    final brand = _guessBrand(deviceName);

    return VehicleData(
      id: (m['id'] ?? '').toString(),
      imei: imei,
      vehicleBrand: brand,
      model: deviceName,
      policeNumber: plate,
      // penting: samakan dengan mapper status di VehicleDataMapper (online/offline)
      status: (m['active']?.toString() == '1') ? 'online' : 'offline',
      picture: const [],
      traccarId: null,
      userId: (m['userid'] ?? '').toString(),
      gsm: (m['msisdn'] ?? '').toString(),
      createdAt: (m['register_date'] ?? '').toString(),
      updatedAt: (m['active_date'] ?? '').toString(),
    );
  }

  static String _extractPlate(String s) {
    final re = RegExp(r'\b[A-Z]{1,2}\s?\d{1,4}\s?[A-Z]{1,3}\b');
    final match = re.firstMatch(s.toUpperCase());
    return match?.group(0)?.trim() ?? '-';
  }

  static String _guessBrand(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'Unknown';
    return parts.first;
  }
}