import 'package:hive/hive.dart';

class PoiLocalImageStore {
  static const _boxName = 'poi_images';

  Box get _box => Hive.box(_boxName);

  Future<void> saveImagePath({
    required int poiId,
    required String imagePath,
  }) async {
    await _box.put(
      poiId.toString(),
      imagePath,
    );
  }

  // Ambil path lokal berdasarkan POI id
  String? getImagePath(int poiId) {
    return _box.get(poiId.toString());
  }

  // Hapus mapping saat POI dihapus
  Future<void> deleteImagePath(int poiId) async {
    await _box.delete(poiId.toString());
  }
}