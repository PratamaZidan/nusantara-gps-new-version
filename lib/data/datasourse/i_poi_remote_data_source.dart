import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:nusantara_gps/core/service/dio_service.dart';
import 'package:nusantara_gps/core/service/poi_local_image_store.dart';
import 'package:nusantara_gps/data/models/poi_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract class IPoiRemoteDataSource {
  Future<List<PoiModel>> fetchListPoi();
  Future<List<String>> fetchListIcon();
  Future<void> savePoi({
    required String nama,
    required String keterangan,
    required double lat,
    required double lng,
    required String icon,
    int? id,
    File? photoFile,
    String? photoName,
  });
  Future<void> deletePoi({required int id});
}

class PoiRemoteDataSourceImpl implements IPoiRemoteDataSource {
  final DioService _dioService;
  final _localImageStore = PoiLocalImageStore();

  PoiRemoteDataSourceImpl(this._dioService);

  // List POI
  @override
  Future<List<PoiModel>> fetchListPoi() async {
    final response = await _dioService.dio.get(
      'hrpc.php',
      queryParameters: const {'act': 'listpoi'},
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );
    final json = _toMap(response.data);
    final raw = json['root'];
    if (raw == null || raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final poi = PoiModel.fromJson(Map<String, dynamic>.from(item));
      return poi.copyWith(localImagePath: _localImageStore.getImagePath(poi.id));
    }).toList();
  }

  // List Icon
  static const _defaultIcons = [
    'm/marker_blackA.png',
    'm/marker_greenA.png',
    'm/marker_orangeA.png',
    'm/marker_purpleA.png',
    'm/marker_yellowA.png',
    'm/marker_whiteA.png',
    'm/marker_greyA.png',
    'm/marker_brownA.png',
    'm/marker_black.png',
    'm/marker_green.png',
    'm/marker_orange.png',
    'm/marker_purple.png',
    'm/marker_yellow.png',
    'm/marker_white.png',
    'm/marker_grey.png',
    'm/markerA.png',
  ];

  @override
  Future<List<String>> fetchListIcon() async {
    try {
      final response = await _dioService.dio.get(
        'hrpc.php',
        queryParameters: const {'act': 'listicon'},
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (c) => c != null && c >= 200 && c < 400,
        ),
      );
      final json = _toMap(response.data);
      final raw = json['root'];
      if (raw != null && raw is List && raw.isNotEmpty) {
        return raw.map((e) => e.toString()).toList();
      }
      return _defaultIcons;
    } catch (_) {
      return _defaultIcons;
    }
  }

  // Save
  @override
  Future<void> savePoi({
    required String nama,
    required String keterangan,
    required double lat,
    required double lng,
    required String icon,
    int? id,
    File? photoFile,
    String? photoName,
  }) async {
    final isCreate = id == null;
    const act = 'addpoi';
    const defaultIcon = 'm/marker_blackA.png';

    final formData = FormData();

    // Field teks biasa
    formData.fields
      ..add(MapEntry('nama', nama))
      ..add(MapEntry('keterangan', keterangan))
      ..add(MapEntry('latitude', lat.toString()))
      ..add(MapEntry('longitude', lng.toString()))
      ..add(MapEntry('micon', icon.isNotEmpty ? icon : defaultIcon));

    if (!isCreate) {
      formData.fields.add(MapEntry('id', id.toString()));
    }

    if (photoFile != null) {
      final stablePhoto = await _stableFile(photoFile);
      final exists = await stablePhoto.exists();
      final fileSize = exists ? await stablePhoto.length() : 0;

      if (exists && fileSize > 0) {
        final fileName = p.basename(photoFile.path);
        final ext = p.extension(fileName).toLowerCase();
        final mimeType = (ext == '.png') ? 'image/png'
            : (ext == '.gif') ? 'image/gif'
            : 'image/jpeg';

        // Part 1: text — nilai yang PHP baca sebagai $_POST['mphoto']
        final fakepathValue = 'C:\\fakepath\\$fileName';
        formData.fields.add(MapEntry('mphoto', fakepathValue));

        // Part 2: file — binary yang PHP baca sebagai $_FILES['mphoto']
        formData.files.add(MapEntry(
          'mphoto',
          await MultipartFile.fromFile(
            stablePhoto.path,
            filename: fileName,
            contentType: DioMediaType.parse(mimeType),
          ),
        ));
      }
    } else if (photoName != null && photoName.isNotEmpty) {
      formData.fields.add(MapEntry('mphoto', photoName));
    }

    await _dioService.dio.post(
      'rpc.php',
      queryParameters: {'act': act},
      data: formData,
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (c) => c != null && c >= 200 && c < 400,
        headers: {'Accept': '*/*'},
      ),
    );
  }

  // Delete
  @override
  Future<void> deletePoi({required int id}) async {
    await _dioService.dio.get(
      'rpc.php',
      queryParameters: {'act': 'delpoi', 'id': id},
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );
  }

  // Helper: copy file dari temp cache ke permanent storage supaya tidak expired
  Future<File> _stableFile(File original) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tmpDir = Directory('${appDir.path}/poi_upload_tmp');
      if (!await tmpDir.exists()) await tmpDir.create(recursive: true);

      final ext = p.extension(original.path);
      final dest = '${tmpDir.path}/upload_${DateTime.now().millisecondsSinceEpoch}$ext';
      return await original.copy(dest);
    } catch (_) {
      return original; // fallback ke file asli kalau copy gagal
    }
  }

  // Helper
  Map<String, dynamic> _toMap(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    return {};
  }
}