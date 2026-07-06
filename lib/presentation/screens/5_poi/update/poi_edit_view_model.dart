import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/core/utils/inconsistent_value_extention.dart';
import 'package:nusantara_gps/data/models/poi_model.dart';
import 'package:nusantara_gps/domain/event/data_invalidation_bus.dart';
import 'package:nusantara_gps/domain/interfaces/i_poi_repository.dart';

class PoiEditViewModel extends ChangeNotifier {
  final IPoiRepository _poiRepo;
  final DataInvalidationBus _bus;
  final _picker = ImagePicker();

  PoiEditViewModel(this._poiRepo, this._bus);

  // Controllers
  final namaController = TextEditingController();
  final keteranganController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();

  // State Foto
  File? _photoFile;
  File? get photoFile => _photoFile;

  // URL foto yang sudan ada
  String _existingPhotoUrl = '';
  String get existingPhotoUrl => _existingPhotoUrl;
  String? _localImagePath;
  String? get localImagePath => _localImagePath;
  String _photoName = '';

  bool get hasExistingPhoto => _localImagePath != null || _existingPhotoUrl.isNotEmpty;
  bool get hasNewPhoto => _photoFile != null;

  // State Icon
  List<String> _iconList = [];
  List<String> get iconList => _iconList;

  String _selectedIcon = 'm/marker_blackA.png';
  String get selectedIcon => _selectedIcon;

  // State Loading
  late int _poiId;
  int get poiId => _poiId;

  ResultState _saveState = ResultState.initial;
  ResultState get saveState => _saveState;

  ResultState _iconLoadState = ResultState.initial;
  ResultState get iconLoadState => _iconLoadState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Init
  void initFromPoi(PoiModel poi) {
    _poiId = poi.id;
    namaController.text = poi.nama;
    keteranganController.text = poi.keterangan;
    latController.text = poi.lat.toString();
    lngController.text = poi.lng.toString();
    _selectedIcon = poi.icon.isNotEmpty ? poi.icon : 'm/marker_blackA.png';
    _existingPhotoUrl = poi.fullPhotoUrl;
    _localImagePath = poi.localImagePath;
    _photoName = poi.photo;
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

  void removeNewPhoto() {
    _photoFile = null;
    notifyListeners();
  }

  // Icon
  void selectIcon(String icon) {
    _selectedIcon = icon;
    notifyListeners();
  }

  // Map
  Set<Marker> buildMarkers() => {
    Marker(
      markerId: const MarkerId('edit_pos'),
      position: LatLng(
        stringToDouble(latController.text), 
        stringToDouble(lngController.text),
      ),
    ),
  };

  void setLatLng(LatLng latlng) {
    latController.text = latlng.latitude.toString();
    lngController.text = latlng.longitude.toString();
    notifyListeners();
  }

  // Validasi
  bool get isValid =>
      namaController.text.trim().isNotEmpty &&
      latController.text.trim().isNotEmpty &&
      lngController.text.trim().isNotEmpty &&
      (hasExistingPhoto || hasNewPhoto);

  // Save
  Future<void> savePoi() async {
    if (!isValid) {
      _errorMessage = namaController.text.trim().isEmpty
          ? 'Nam wajib diisi'
          : (!hasExistingPhoto && !hasNewPhoto)
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
      await _poiRepo.updatePoi(
        id: _poiId, 
        nama: namaController.text.trim(), 
        keterangan: keteranganController.text.trim(), 
        lat: stringToDouble(latController.text), 
        lng: stringToDouble(lngController.text),
        micon: _selectedIcon,
        photoFile: _photoFile,
        photoName: _photoFile == null ? _photoName : null,
      );
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