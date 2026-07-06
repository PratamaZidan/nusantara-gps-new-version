sealed class Failure {
  final String message;
  const Failure(this.message);
}

class InvalidCredentials extends Failure {
  const InvalidCredentials() : super('Email atau password salah.');
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Koneksi bermasalah. Coba lagi.');
}

class ServerFailure extends Failure {
  const ServerFailure([super.msg = 'Terjadi kesalahan server.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.msg = 'Terjadi kesalahan tak terduga.']);
}
