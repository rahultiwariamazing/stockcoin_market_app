// File: lib/core/errors/result.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'app_failure.dart';

sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    final value = this;
    if (value is ResultSuccess<T>) {
      return success(value.data);
    }

    if (value is ResultFailure<T>) {
      return failure(value.failure);
    }

    throw StateError('Unhandled Result state');
  }
}

class ResultSuccess<T> extends Result<T> {
  final T data;

  const ResultSuccess(this.data);
}

class ResultFailure<T> extends Result<T> {
  final AppFailure failure;

  const ResultFailure(this.failure);
}
