sealed class Result<T, E> {
  const Result();
  R match<R>(R Function(T) ok, R Function(E) err) => switch (this) {
    Success<T, E>(:final value) => ok(value),
    Error<T, E>(:final error) => err(error),
  };
}

class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

class Error<T, E> extends Result<T, E> {
  final E error;
  const Error(this.error);
}

enum FailureType {
  invalidCredentials,
  network,
  server,
  rateLimited,
  malformedResponse,
  unknown,
}

class Failure {
  final FailureType type;
  final String message;
  final int? statusCode;
  const Failure(this.type, this.message, {this.statusCode});
}

enum ResultState { initial, loading, success, noData, error }
