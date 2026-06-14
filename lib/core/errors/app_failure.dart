// File: lib/core/errors/app_failure.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

enum FailureType {
  network,
  timeout,
  server,
  storage,
  validation,
  parsing,
  unknown,
}

class AppFailure implements Exception {
  final FailureType type;
  final String message;
  final Object? cause;

  const AppFailure({
    required this.type,
    required this.message,
    this.cause,
  });

  factory AppFailure.fromException(Object error) {
    if (error is AppFailure) {
      return error;
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return AppFailure(
          type: FailureType.timeout,
          message: 'Request timed out. Please try again.',
          cause: error,
        );
      }

      if (error.type == DioExceptionType.connectionError) {
        return AppFailure(
          type: FailureType.network,
          message: 'No internet connection. Please check network.',
          cause: error,
        );
      }

      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        if (statusCode == 429) {
          return AppFailure(
            type: FailureType.server,
            message: 'Rate limit reached (429). Please wait a moment and try again.',
            cause: error,
          );
        }

        return AppFailure(
          type: FailureType.server,
          message: 'Server error ($statusCode). Please try again.',
          cause: error,
        );
      }

      return AppFailure(
        type: FailureType.network,
        message: 'Network request failed. Please try again.',
        cause: error,
      );
    }

    if (error is HiveError) {
      return AppFailure(
        type: FailureType.storage,
        message: 'Local storage error. Please retry.',
        cause: error,
      );
    }

    if (error is FormatException) {
      return AppFailure(
        type: FailureType.parsing,
        message: 'Data format is invalid.',
        cause: error,
      );
    }

    return AppFailure(
      type: FailureType.unknown,
      message: 'Something went wrong. Please try again.',
      cause: error,
    );
  }
}
