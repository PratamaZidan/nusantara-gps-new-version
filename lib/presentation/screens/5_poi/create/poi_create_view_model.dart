import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/core/utils/inconsistent_value_extention.dart';
import 'package:nusantara_gps/domain/event/data_invalidation_bus.dart';
import 'package:nusantara_gps/domain/interfaces/i_poi_repository.dart';
// import 'package:nusantara_gps/core/service/local_poi_image_service.dart';
// import 'package:nusantara_gps/core/service/poi_local_image_store.dart';

class PoiCreateViewModel extends ChangeNotifier {
  final IPoiRepository _poiRepo;
  final DataInvalidationBus _bus;
  final _picker = ImagePicker();
  // final _localImagesService = LocalPoiImageService();
  // final _localImageStore = PoiLocalImageStore();

  PoiCreateViewModel(this._poiRepo, this._bus);

  // Controllers
  final namaController = TextEditingController();
  final keteranganController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();

  // State Foto & Icon
  File? _photoFile;
  File? get photoFile => _photoFile;

  List<String> _iconList = [];
  List<String> get iconList => _iconList;

  String _selectedIcon = 'm/marker_blackA.png'; // Default Icon
  String get selectedIcon => _selectedIcon;

  // State Loading
  ResultState _saveState = ResultState.initial;
  ResultState get saveState => _saveState;

  ResultState _iconLoadState = ResultState.initial;
  ResultState get iconLoadState => _iconLoadState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Init
  void setInitialLatLng(double lat, double lng) {
    latController.text = lat.toString();
    lngController.text = lng.toString();
  }

  Future<void> loadIcons() async {
    _iconLoadState = ResultState.loading;
    notifyListeners();
    try {
      _iconList = await _poiRepo.getIcons();
      if (_iconList.isNotEmpty && !_iconList.contains(_selectedIcon)) {
        _selectedIcon = _iconList.first;
      }
      _iconLoadState = ResultState.success;
    } catch (_) {
      _iconLoadState = ResultState.error;
    } finally {
      notifyListeners();
    }
  }

  // Foto
  Future<void> pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked != null) {
      _photoFile = File(picked.path);
      notifyListeners();
    }
  }

  void removePhoto() {
    _photoFile = null;
    notifyListeners();
  }

  // Icon
  void selectIcon(String icon) {
    _selectedIcon = icon;
    notifyListeners();
  }

  // Validasi
  bool get isValid =>
      namaController.text.trim().isNotEmpty &&
      latController.text.trim().isNotEmpty &&
      lngController.text.trim().isNotEmpty &&
      _photoFile != null; // Foto Wajib

  // Save
  Future<void> savePoi() async {
    if (!isValid) {
      _errorMessage = namaController.text.trim().isEmpty
        ? 'Nama wajib diisi'
        : _photoFile == null
            ? 'Foto lokasi wajib diunggah'
            : 'Koordinat wajib diisi';
      _saveState = ResultState.error;
      notifyListeners();
      return;
    }

    _saveState = ResultState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _poiRepo.createPoi(
        nama: namaController.text.trim(), 
        keterangan: keteranganController.text.trim(), 
        lat: stringToDouble(latController.text), 
        lng: stringToDouble(lngController.text),
        micon: _selectedIcon,
        photoFile: _photoFile,
      );

      // Ambil ulang list POI terbaru
      // final pois = await _poiRepo.getPois();
      // final latestPoi = pois.isNotEmpty ? pois.last : null;
      
      // if (latestPoi != null && _photoFile != null) {
      //   final savedPath = await _localImagesService.saveImageLocally(
      //     imageFile: _photoFile!, 
      //     poiId: latestPoi.id,
      //   );

      // await _localImageStore.saveImagePath(
      //   poiId: latestPoi.id, 
      //   imagePath: savedPath,
      //   );
      // }
      
      _saveState = ResultState.success;
      _bus.emit(DataInvalidationEvent.favoriteLocationChanged);
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _saveState = ResultState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _saveState = ResultState.error;
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    keteranganController.dispose();
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }
}