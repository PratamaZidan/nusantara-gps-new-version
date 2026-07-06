import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// Copy gambar yang dikirim user simpan ke folder aplikasi
class LocalPoiImageService {
  Future<String> saveImageLocally({
    required File imageFile,
    required int poiId,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();

    final poiDir = Directory(
      '${appDir.path}/poi_images',
    );

    if (!await poiDir.exists()) {
      await poiDir.create(recursive: true);
    }

    final fileName = 'poi_${poiId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
    final savedImage = await imageFile.copy('${poiDir.path}/$fileName',
    );

    return savedImage.path;
  }

  // Hapus Gambar
  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}