import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PoiIconCache {
  PoiIconCache._();
  static final PoiIconCache instance = PoiIconCache._();
  static const String _baseIconUrl = 'https://lacak.nusantaragps.com/assets/icon/';
  static const double markerWidthDp = 24.0;

  final _cache = <String, BitmapDescriptor>{};
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<BitmapDescriptor?> get(
    String iconPath, {
    double? width,  
    }) async {
    if (iconPath.isEmpty) return null;

    final double targetWidth = width ?? markerWidthDp;
    final cacheKey = '$iconPath@$targetWidth';

    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    try {
      final url = '$_baseIconUrl$iconPath';
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null || response.data!.isEmpty) return null;
      final bytes = Uint8List.fromList(response.data!);
      final descriptor = BitmapDescriptor.bytes(bytes, width: targetWidth);
      _cache[cacheKey] = descriptor;
      return descriptor;
    } catch (_) {
      return null;
    }
  }

  // Pre-load sekumpulan icon sekaligus secara paralel.
  Future<void> preload(Iterable<String> iconPaths, {double? width}) async {
    await Future.wait(
      iconPaths
          .where((p) => p.isNotEmpty)
          .map((p) => get(p, width: width)),
    );
  }

  // Synchronus - hanya return kalau sudah ada di cache
  BitmapDescriptor? getCached(String iconPath, {double? width}) {
    final double targetWidth = width ?? markerWidthDp;
    return _cache['$iconPath@$targetWidth'];
  }

  void clearCache() => _cache.clear();
}