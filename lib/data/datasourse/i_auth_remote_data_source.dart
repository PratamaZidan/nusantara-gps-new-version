import 'package:dio/dio.dart';
import 'package:nusantara_gps/core/service/dio_service.dart';
import 'package:nusantara_gps/data/dto/user_dto.dart';

abstract class IAuthRemoteDataSource {
  Future<UserDTO> login({required String username, required String password});
}

class AuthRemoteDataSourceImpl implements IAuthRemoteDataSource {
  final DioService _dioService;
  AuthRemoteDataSourceImpl(this._dioService);

  @override
  Future<UserDTO> login({
    required String username,
    required String password,
  }) async {
    final dio = _dioService.dio;

    // Login WEB: POST ke "/" (root) dengan form-urlencoded
    final res = await dio.post(
      '',
      data: {
        'username': username,
        'password': password,
        // 'remember': 'on',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false, // penting biar kita bisa lihat 303 + Location
        validateStatus: (c) => c != null && c >= 200 && c < 400,
      ),
    );

    final location = res.headers.value('location') ?? '';
    final ok = res.statusCode == 303 && location.contains('/dashboard');

    if (!ok) {
      throw const FormatException('Kredensial tidak valid');
    }

    return UserDTO(data: Data(username: username));
  }
}