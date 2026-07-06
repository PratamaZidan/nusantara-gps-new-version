import 'package:dio/dio.dart';

String mapDioErrorToMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return 'Waktu koneksi habis. Periksa jaringan Anda.';
    case DioExceptionType.sendTimeout:
      return 'Pengiriman data terlalu lama. Coba lagi.';
    case DioExceptionType.receiveTimeout:
      return 'Server terlalu lama merespon. Coba lagi nanti.';
    case DioExceptionType.badCertificate:
      return 'Sertifikat server tidak valid.';
    case DioExceptionType.badResponse:
      return _handleBadResponse(error);
    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';
    case DioExceptionType.connectionError:
      return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
    default:
      return 'Terjadi kesalahan yang tidak diketahui.';
  }
}

String _handleBadResponse(DioException error) {
  final responseData = error.response?.data;
  final statusCode = error.response?.statusCode;

  if (statusCode == 401) {
    return 'Sesi Anda telah berakhir. Silakan login kembali.';
  }

  if (responseData is Map<String, dynamic>) {
    if (responseData.containsKey('errors')) {
      final errors = responseData['errors'];

      if (errors is Map<String, dynamic>) {
        for (var key in errors.keys) {
          final value = errors[key];
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          if (value is String) {
            return value;
          }
        }
      }
    }

    if (responseData.containsKey('message')) {
      return responseData['message'].toString();
    }
  }

  return 'Terjadi kesalahan pada server ($statusCode).';
}
