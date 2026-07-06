sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.msg);
}

class AuthFailure extends Failure {
  final AuthFailureKind kind;
  const AuthFailure(this.kind, String msg) : super(msg);
}

enum AuthFailureKind { invalidCredential, locked, expired, server, unknown }
