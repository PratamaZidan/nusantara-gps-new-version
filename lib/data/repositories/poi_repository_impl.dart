import 'dart:io';

import 'package:dio/dio.dart';
import 'package:nusantara_gps/data/datasourse/i_poi_remote_data_source.dart';
import 'package:nusantara_gps/data/models/poi_model.dart';
import 'package:nusantara_gps/domain/interfaces/i_poi_repository.dart';
import 'package:nusantara_gps/core/service/local_poi_image_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nusantara_gps/core/service/poi_local_image_store.dart';

class PoiRepositoryImpl implements IPoiRepository {
  final IPoiRemoteDataSource _remote;
  final _localImageService = LocalPoiImageService();
  final _localImageStore = PoiLocalImageStore();

  PoiRepositoryImpl(this._remote);

  // List
  @override
  Future<List<PoiModel>> getPois() async {
    try {
      final pois = await _remote.fetchListPoi();
      return pois.map((poi) {
        final localPath = _localImageStore.getImagePath(poi.id);
        return poi.copyWith(localImagePath: localPath);
      }).toList();
    } on DioException {
      rethrow;
    } 
  }

  @override
  Future<List<String>> getIcons() async {
    try {
      return await _remote.fetchListIcon();
    } on DioException {
      rethrow;
    }
  }

  // Create
  @override
  Future<void> createPoi({
    required String nama,
    required String keterangan,
    required double lat,
    required double lng,
    required String micon,
    File? photoFile
  }) async {
    try {
      await _remote.savePoi(
        nama: nama, 
        keterangan: keterangan, 
        lat: lat, 
        lng: lng,
        icon: micon,
        id: null,
        photoFile: photoFile,
      );

      if (photoFile != null) {
        final pois = await _remote.fetchListPoi();
        final newPoi = pois.isNotEmpty
            ? pois.reduce((a, b) => a.id > b.id ? a : b)
            : null;

        if (newPoi != null) {
          final savedPath = await _localImageService.saveImageLocally(
            imageFile: photoFile, 
            poiId: newPoi.id,
          );
          await _localImageStore.saveImagePath(
            poiId: newPoi.id, 
            imagePath: savedPath,
          );
        }

        // Bersihkan file temp upload di poi_upload_tmp
        _cleanUploadTmp();
      }
    } on DioException {
      rethrow;
    }
  }

  void _cleanUploadTmp() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tmpDir = Directory('${appDir.path}/poi_upload_tmp');
      if (await tmpDir.exists()) {
        await tmpDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  // Update
  @override
  Future<void> updatePoi({
    required int id,
    required String nama,
    required String keterangan,
    required double lat,
    required double lng,
    required String micon,
    File? photoFile,
    String? photoName,
  }) async {
    try {
      await _remote.savePoi(
        id: id, 
        nama: nama, 
        keterangan: keterangan, 
        lat: lat, 
        lng: lng,
        icon: micon,
        photoFile: photoFile,
        photoName: photoName,
      );

      if (photoFile != null) {
        final oldPath = _localImageStore.getImagePath(id);
        if (oldPath != null) {
          try {
            await _localImageService.deleteImage(oldPath);
          } catch (_) {}
        }

        final savedPath = await _localImageService.saveImageLocally(
          imageFile: photoFile, 
          poiId: id,
        );
        await _localImageStore.saveImagePath(
          poiId: id, 
          imagePath: savedPath,
        );
      }
    } on DioException {
      rethrow;
    }
  }

  // Delete
  @override
  Future<void> deletePoi({required int id}) async {
    try {
      await _remote.deletePoi(id: id);

      final localPath = _localImageStore.getImagePath(id);
      if (localPath != null) {
        try {
        await _localImageService.deleteImage(localPath);
        } catch (_) {}
        
        await _localImageStore.deleteImagePath(id);
      }
    } on DioException {
      rethrow;
    }
  }
}