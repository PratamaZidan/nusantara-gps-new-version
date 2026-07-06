import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:nusantara_gps/core/service/dio_service.dart';
import 'package:nusantara_gps/domain/interfaces/i_profile_repository.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  final DioService _dioService;
  ProfileRepositoryImpl(this._dioService);

  // Get Profile
  @override
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dioService.dio.get(
      'rpc.php',
      queryParameters: {'act': 'getProfile'},
      options: Options(responseType: ResponseType.json),
    );

    final data = _parse(response.data);
    if (data['ok'] != true) {
      throw Exception('Gagal mengambil profil');
    }
    return Map<String, dynamic>.from(data);
  }

  // Edit Profile
  @override
  Future<void> editProfile({
    required String username,
    required String name,
    required String phone,
    required String email,
  }) async {
    final response = await _dioService.dio.post(
      'rpc.php',
      queryParameters: {'act': 'editprofile'},
      data: {
        'username': username,
        'name': name,
        'phone': phone,
        'email': email,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.json,
      ),
    );

    final data = _parse(response.data);
    final ok = data['ok'] == true || data['success'] == true;
    if (!ok) {
      final msg = data['msg']?.toString() ?? data['message']?.toString() ?? 'Gagal menyimpan profil';
      throw Exception(msg);
    }
  }

  // Change Password
  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _dioService.dio.post(
      'rpc.php',
      queryParameters: {'act': 'editprofile'},
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'password': newPassword,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.json,
      ),
    );

    final data = _parse(response.data);
    final ok = data['ok'] == true || data['success'] == true;
    if (!ok) {
      final msg = data['msg']?.toString() ?? data['message']?.toString() ?? 'Gagal mengubah password';
      throw Exception(msg);
    }
  }

  // Helper
  Map<String, dynamic> _parse(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final decoded = jsonDecode(raw);
      return Map<String, dynamic>.from(decoded as Map);
    }
    return {};
  }
}