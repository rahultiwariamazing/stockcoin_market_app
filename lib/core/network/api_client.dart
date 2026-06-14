// File: lib/core/network/api_client.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:dio/dio.dart';

// Central API client (single place to manage all network calls)
class ApiClient {
  static DateTime? _rateLimitCooldownUntil;
  static Duration _rateLimitBackoff = const Duration(seconds: 20);
  static const int _maxBackoffSeconds = 300;
  static DateTime? _lastCooldownLogAt;

  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: "https://api.coingecko.com/api/v3/",
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _addInterceptors();
  }

  // Add interceptors (logging + future auth tokens)
  void _addInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(

        // Request
        onRequest: (options, handler) {
          final now = DateTime.now();
          if (_rateLimitCooldownUntil != null &&
              now.isBefore(_rateLimitCooldownUntil!)) {
            final shouldLog = _lastCooldownLogAt == null ||
                now.difference(_lastCooldownLogAt!).inSeconds >= 5;

            if (shouldLog) {
              final remaining =
                  _rateLimitCooldownUntil!.difference(now).inSeconds;
              print('⏳ RATE LIMIT COOLDOWN ACTIVE: skipping request for ${remaining}s');
              _lastCooldownLogAt = now;
            }

            final response = Response(
              requestOptions: options,
              statusCode: 429,
              statusMessage:
                  'Local cooldown active due to previous CoinGecko rate-limit response',
            );

            return handler.reject(
              DioException(
                requestOptions: options,
                response: response,
                type: DioExceptionType.badResponse,
                error: 'Local rate-limit cooldown active',
              ),
            );
          }

          print("➡️ REQUEST: ${options.method} ${options.uri}");
          return handler.next(options);
        },

        // Response
        onResponse: (response, handler) {
          if ((response.statusCode ?? 0) >= 200 &&
              (response.statusCode ?? 0) < 300) {
            _rateLimitCooldownUntil = null;
            _rateLimitBackoff = const Duration(seconds: 20);
          }

          print("✅ RESPONSE: ${response.statusCode}");
          return handler.next(response);
        },

        // Error
        onError: (error, handler) {
          final statusCode = error.response?.statusCode;
          if (statusCode == 429) {
            final retryAfter = error.response?.headers.value('retry-after');
            final retryAfterSeconds = int.tryParse(retryAfter ?? '');

            if (retryAfterSeconds != null && retryAfterSeconds > 0) {
              _rateLimitCooldownUntil =
                  DateTime.now().add(Duration(seconds: retryAfterSeconds));
            } else {
              _rateLimitCooldownUntil =
                  DateTime.now().add(_rateLimitBackoff);

              final doubled = _rateLimitBackoff.inSeconds * 2;
              final nextSeconds =
                  doubled > _maxBackoffSeconds ? _maxBackoffSeconds : doubled;
              _rateLimitBackoff = Duration(seconds: nextSeconds);
            }
          }

          print("❌ ERROR: ${error.message}");
          return handler.next(error);
        },
      ),
    );
  }
}
