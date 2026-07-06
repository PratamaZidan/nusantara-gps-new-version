import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/service/alert_polling_service.dart'; // ← BARU
import 'package:nusantara_gps/core/service/storage/i_key_value_storage.dart';
import 'package:nusantara_gps/data/datasourse/i_auth_remote_data_source.dart';
import 'package:nusantara_gps/data/dto/user_dto.dart';
import 'package:nusantara_gps/data/models/user_model.dart';
import 'package:nusantara_gps/domain/interfaces/i_auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← BARU

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource _remote;
  final IKeyValueStorage _storage;
  final CookieJar _cookieJar;

  AuthRepositoryImpl(this._remote, this._storage, this._cookieJar);

  @override
  Future<Result<User, Failure>> login(String username, String password) async {
    try {
      // Login (WEB) => akan set cookie PHPSESSID via CookieJar interceptor Dio
      final dto = await _remote.login(username: username, password: password);
      final user = dto.toEntity();

      // Simpan kredensial untuk re-login otomatis (silent) saat app dibuka ulang
      await _storage.setString(PrefKeys.userRaw, _serialize(dto));
      await _storage.setString(PrefKeys.username, dto.data?.username ?? username);
      await _storage.setString(PrefKeys.password, password);
      await _savePHPSessionId();
      

      return Success(user);
    } on DioException catch (e) {
      final sc = e.response?.statusCode;

      if (sc == 401 || sc == 400) {
        return Error(
          Failure(
            FailureType.invalidCredentials,
            'Username atau password salah.',
            statusCode: sc,
          ),
        );
      }
      if (sc == 429) {
        return Error(
          Failure(
            FailureType.rateLimited,
            'Terlalu banyak percobaan. Coba lagi beberapa menit lagi.',
            statusCode: sc,
          ),
        );
      }
      if (sc != null && sc >= 500) {
        return Error(
          Failure(
            FailureType.server,
            'Server bermasalah. Coba lagi nanti.',
            statusCode: sc,
          ),
        );
      }
      return Error(
        Failure(
          FailureType.network,
          'Koneksi bermasalah. Periksa internet Anda.',
          statusCode: sc,
        ),
      );
    } on FormatException catch (e) {
      final isInvalidCreds = e.message.contains('Kredensial');
      return Error(
        Failure(
          isInvalidCreds ? FailureType.invalidCredentials : FailureType.malformedResponse,
          isInvalidCreds ? 'Username atau password salah.' : 'Respon server tidak sesuai skema.',
        ),
      );
    } catch (_) {
      return Error(
        const Failure(
          FailureType.unknown,
          'Terjadi kesalahan yang tidak dikenal.',
        ),
      );
    }
  }

  @override
  Future<bool> checkSession() async {
    final username = await _storage.getString(PrefKeys.username);
    final password = await _storage.getString(PrefKeys.password);

    if (username == null || username.isEmpty || password == null || password.isEmpty) {
      return false;
    }

    try {
      // Silent re-login untuk membentuk ulang PHPSESSID cookie
      await _remote.login(username: username, password: password);
      await _savePHPSessionId();

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> logout() async {
    // Hapus semua data session dari storage
    await _storage.remove(PrefKeys.userRaw);
    await _storage.remove(PrefKeys.username);
    await _storage.remove(PrefKeys.password);
    await _storage.remove(PrefKeys.token);
    await _storage.remove(PrefKeys.traccarToken);
    await _storage.remove(PrefKeys.email);
    await _storage.remove(PrefKeys.phone);

    // Hapus PHPSESSID dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth.phpsessid');

    // Hapus cookie session PHP
    await _cookieJar.deleteAll();

    // Hentikan background polling
    await AlertPollingService.instance.stopService();
  }

  // Simpan PHPSESSID ke SharedPreferences
  Future<void> _savePHPSessionId() async {
    try {
      final uri = Uri.parse('https://lacak.nusantaragps.com/');
      final cookies = await _cookieJar.loadForRequest(uri);

      final sessionCookie = cookies.firstWhere(
        (c) => c.name == 'PHPSESSID',
        orElse: () => throw Exception('PHPSESSID tidak ditemukan di CookieJar'),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth.phpsessid', sessionCookie.value);

      print('[Auth] PHPSESSID berhasil disimpan untuk background service');
    } catch (e) {
      // Silent — tidak crash login hanya karena PHPSESSID gagal disimpan
      print('[Auth] Gagal simpan PHPSESSID: $e');
    }
  }

  String _serialize(UserDTO dto) {
    return jsonEncode({
      'username': dto.data?.username ?? '',
    });
  }
}

class PrefKeys {
  static const userRaw      = 'auth.user.raw';
  static const token        = 'auth.token';
  static const traccarToken = 'auth.traccartoken';
  static const email        = 'auth.email';
  static const username     = 'auth.username';
  static const password     = 'auth.password';
  static const phone        = 'auth.phone';
  static const phpsessid    = 'auth.phpsessid';
  static const profilePhotoPath = 'auth.profile_photo_path';
}