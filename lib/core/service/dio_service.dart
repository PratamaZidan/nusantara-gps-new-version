import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio/dio.dart';
import 'package:nusantara_gps/domain/manager/session_manager.dart';

class DioService {
  final Dio dio;
  final CookieJar cookieJar;

  DioService._(this.dio, this.cookieJar);

  factory DioService({
    required String baseUrl,
    required SessionManager sessionManager,
    CookieJar? sharedCookieJar,
  }) {
    final jar = sharedCookieJar ?? CookieJar();
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(CookieManager(jar));

    dio.interceptors.add(CrossPathCookieInterceptor(jar, baseUrl));

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
        error: true,
        logPrint: (object) => print(object),
      ),
    );
    dio.interceptors.add(AuthInterceptor(sessionManager));
    return DioService._(dio, jar);
  }
}

class CrossPathCookieInterceptor extends Interceptor {
  final CookieJar _jar;
  final String _baseUrl;

  CrossPathCookieInterceptor(this._jar, this._baseUrl);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // Ambil cookie dari root domain (path = '/'). Ini yang menyimpan PHPSESSID saat login
      final rootUri = Uri.parse(_baseUrl.contains('lacak.nusantaragps.com')
          ? 'https://lacak.nusantaragps.com/'
          : _baseUrl);

      final cookies = await _jar.loadForRequest(rootUri);

      if (cookies.isNotEmpty) {
        final cookieHeader =
            cookies.map((c) => '${c.name}=${c.value}').join('; ');

        // Merge dengan cookie yang sudah ada (jangan overwrite)
        final existing = options.headers['cookie'] ?? '';
        if (existing.isEmpty) {
          options.headers['cookie'] = cookieHeader;
        } else if (!existing.contains('PHPSESSID')) {
          options.headers['cookie'] = '$existing; $cookieHeader';
        }
      }
    } catch (_) {
      // Jangan crash jika gagal load cookie
    }

    handler.next(options);
  }
}

class AuthInterceptor extends Interceptor {
  final SessionManager sessionManager;

  AuthInterceptor(this.sessionManager);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      sessionManager.logout();
    }
    handler.next(err);
  }
}