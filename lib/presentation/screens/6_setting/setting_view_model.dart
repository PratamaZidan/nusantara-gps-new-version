import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/service/storage/i_key_value_storage.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/data/repositories/auth_repository_impl.dart';
import 'package:nusantara_gps/domain/interfaces/i_auth_repository.dart';
import 'package:nusantara_gps/domain/interfaces/i_profile_repository.dart';
import 'package:path_provider/path_provider.dart';

class SettingViewModel extends ChangeNotifier {
  final IAuthRepository _auth;
  final IKeyValueStorage _storage;
  final IProfileRepository _profileRepo;

  SettingViewModel(this._auth, this._storage, this._profileRepo);

  // Data Profil
  String? _name;
  String? _phone;
  String? _email;
  String? _photo;
  String? _username;

  String? get name => _name;
  String? get phone => _phone;
  String? get email => _email;
  String? get photo => _photo;
  String? get username => _username;

  // Foto Profil Lokal
  String? _localPhotoPath;
  String? get localPhotoPath => _localPhotoPath;

  // State
  ResultState _loadState = ResultState.loading;
  ResultState get loadState => _loadState;

  ResultState _saveState = ResultState.initial;
  ResultState get saveState => _saveState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Load Profil dari API + lokal
  Future<void> load() async {
    _loadState = ResultState.loading;
    notifyListeners();
    
    try {
      _name = await _storage.getString(PrefKeys.username);
      _phone = await _storage.getString(PrefKeys.phone);
      _email = await _storage.getString(PrefKeys.email);
      _username = await _storage.getString(PrefKeys.username);

      // Sync ke storage lokal untuk dipakai bg service/offline
      await _storage.setString(PrefKeys.username, _username ?? '');
      await _storage.setString(PrefKeys.phone, _phone ?? '');
      await _storage.setString(PrefKeys.email, _email ?? '');

      // Load foto dari lokal storage
      _localPhotoPath = await _storage.getString(PrefKeys.profilePhotoPath);

      _loadState = ResultState.success;
    } catch (_) {
      _name = await _storage.getString(PrefKeys.username);
      _phone = await _storage.getString(PrefKeys.phone);
      _email = await _storage.getString(PrefKeys.email);
      _localPhotoPath = await _storage.getString(PrefKeys.profilePhotoPath);
      _loadState = ResultState.success;
    } finally {
      notifyListeners();
    }
  }

  // Edit Profil
  Future<bool> saveProfile({
    required String name,
    required String phone,
    required String email,
  }) async {
    _saveState = ResultState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepo.editProfile(
        username: _username ?? '',
        name: name,
        phone: phone,
        email: email,
      );

      // Update lokal
      _name = name;
      _phone = phone;
      _email = email;

      await _storage.setString(PrefKeys.username, name);
      await _storage.setString(PrefKeys.phone, phone);
      await _storage.setString(PrefKeys.email, email);

      _saveState = ResultState.success;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _saveState = ResultState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _saveState = ResultState.error;
      notifyListeners();
      return false;
    }
  }

  // Ubah Password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _saveState = ResultState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepo.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      _saveState = ResultState.success;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _saveState = ResultState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _saveState = ResultState.error;
      notifyListeners();
      return false;
    }
  }

  // Pilih & Simpan foto lokal
  Future<void> pickAndSavePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      // Salin ke direktori permanen APP
      final appDir = await getApplicationDocumentsDirectory();
      final dest = File('${appDir.path}/profile_photo.jpg');
      await File(picked.path).copy(dest.path);

      // Simpan path ke storage
      _localPhotoPath = dest.path;
      await _storage.setString(PrefKeys.profilePhotoPath, dest.path);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memilih foto: $e';
      notifyListeners();
    }
  }

  Future<void> removePhoto() async {
    _localPhotoPath = null;

    await _storage.remove(PrefKeys.profilePhotoPath);

    notifyListeners();
  }

  // Logout
  Future<void> logout(BuildContext context) async {
    await _auth.logout();
    if (!context.mounted) return;
    context.go('/login');
  }
}
