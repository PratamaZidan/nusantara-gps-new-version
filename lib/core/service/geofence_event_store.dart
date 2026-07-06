import 'dart:convert';
import 'package:hive/hive.dart';

// Model untuk 1 event geofence (in/out)
class GeofenceEventModel {
  final String id;
  final String deviceId;
  final String deviceName;
  final String geofenceId;
  final String geofenceName;
  final bool isEntering; 
  final String timestamp;

  const GeofenceEventModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.geofenceId,
    required this.geofenceName,
    required this.isEntering,
    required this.timestamp,
  });

  factory GeofenceEventModel.fromJson(Map<String, dynamic> json) {
    return GeofenceEventModel(
      id: json['id']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? '',
      geofenceId: json['geofenceId']?.toString() ?? '',
      geofenceName: json['geofenceName']?.toString() ?? '',
      isEntering: json['isEntering'] as bool,
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'geofenceId': geofenceId,
    'geofenceName': geofenceName,
    'isEntering': isEntering,
    'timestamp': timestamp,
  };

  String get formattedMessage => isEntering
      ? 'Kendaraan memasuki area $geofenceName'
      : 'Kendaraan keluar dari area $geofenceName';
}

// Local store untuk event geofence menggunakan hive
class GeofenceEventStore {
  static const _boxName = 'geofence_events';
  static const _maxItems = 100; // Simpan maksimal 100 event terbaru

  Box get _box => Hive.box(_boxName);

  // Simpan event baru. Kalau sudah > _maxItems, hapus yang paling lama.
  Future<void> saveEvent(GeofenceEventModel event) async {
    await _box.put(event.id, jsonEncode(event.toJson()));

    // Trim kalau sudah overload
    if (_box.length > _maxItems) {
      final keys = _box.keys.toList();
      final toDelete = keys.take(_box.length - _maxItems).toList();
      await _box.deleteAll(toDelete);
    }
  }

  // Ambil semua event, diurutkan dari yg terbaru
  List<GeofenceEventModel> getAll() {
    final events = _box.values
        .map((raw) {
          try {
            final map = jsonDecode(raw.toString()) as Map<String, dynamic>;
            return GeofenceEventModel.fromJson(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<GeofenceEventModel>()
        .toList();

    // Sort descending by timestamp 
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  // Hapus semua event
  Future<void> clearAll() async {
    await _box.clear();
  }

  int get count => _box.length;
}