import 'dart:io';
import 'package:nusantara_gps/data/models/poi_model.dart';

abstract class IPoiRepository {
  Future<List<PoiModel>> getPois();
  Future<List<String>> getIcons();

  Future<void> createPoi({
    required String nama,
    required String keterangan,
    required double lat,
    required double lng,
    required String micon,
    File? photoFile,
  });

  Future<void> updatePoi({
    required int id,
    required String nama,
    required String keterangan,
    required double lat,
    required double lng,
    required String micon,
    File? photoFile,
    String? photoName,
  });

  Future<void> deletePoi({required int id});
}