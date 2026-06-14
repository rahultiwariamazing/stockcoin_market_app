// File: lib/features/crypto/data/services/crypto_service.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/network/api_client.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';

// MAUI map: Service = HTTP client layer (like API service class in .NET).
// This file should only know about endpoints + raw API payloads.
// It should not know UI rules or widget state.

/// ✅ Service layer for Crypto APIs
/// 
/// 📌 Responsibilities:
/// - Fetch market list ✅
/// - Fetch historical data (NEW ✅)
/// - Handle API communication
class CryptoService {

  final ApiClient _apiClient = ApiClient();

  /// ✅ Fetch Crypto Market Data (already working ✅)
  Future<Result<List<dynamic>>> getCryptoMarkets({int page = 1}) async {
    try {
      // Raw API call for paginated market list.
      final response = await _apiClient.dio.get(
        'coins/markets',
        queryParameters: {
          'vs_currency': 'inr',
          'order': 'market_cap_desc',
          'per_page': 20,
          'page': page,
          'sparkline': false,
        },
      );

      return ResultSuccess(List<dynamic>.from(response.data));

    } catch (e) {
      return ResultFailure(AppFailure.fromException(e));
    }
  }

  Future<Result<List<dynamic>>> getCryptoMarketsByIds({
    required List<String> ids,
  }) async {
    try {
      // Guard: avoid unnecessary API call.
      if (ids.isEmpty) {
        return const ResultSuccess(<dynamic>[]);
      }

      final response = await _apiClient.dio.get(
        'coins/markets',
        queryParameters: {
          'vs_currency': 'inr',
          'ids': ids.join(','),
          'order': 'market_cap_desc',
          'sparkline': false,
        },
      );

      return ResultSuccess(List<dynamic>.from(response.data));
    } catch (e) {
      return ResultFailure(AppFailure.fromException(e));
    }
  }

  Future<Result<List<String>>> searchCoinIds({
    required String query,
  }) async {
    try {
      // Guard: ignore too-short queries to reduce API pressure.
      if (query.trim().length < 2) {
        return const ResultSuccess(<String>[]);
      }

      final response = await _apiClient.dio.get(
        'search',
        queryParameters: {'query': query},
      );

      final coins = List<Map<String, dynamic>>.from(
        response.data['coins'] ?? <Map<String, dynamic>>[],
      );

      final ids = coins
          .map((coin) => (coin['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          // Limit ids to keep follow-up market request fast and stable.
          .take(10)
          .toList();

      return ResultSuccess(ids);
    } catch (e) {
      return ResultFailure(AppFailure.fromException(e));
    }
  }

  Future<Result<List<dynamic>>> searchCryptoMarkets({
    required String query,
  }) async {
    // Step 1: get matching coin ids from search endpoint.
    final idsResult = await searchCoinIds(query: query);

    // Step 2: resolve those ids into market rows for UI cards.
    return idsResult.when(
      success: (ids) async {
        if (ids.isEmpty) {
          return const ResultSuccess(<dynamic>[]);
        }

        return getCryptoMarketsByIds(ids: ids);
      },
      failure: (failure) async => ResultFailure(failure),
    );
  }

  /// ✅ ✅ NEW — Fetch Historical Data for Graph
  /// 
  /// 📌 Used in: Crypto Details Screen
  /// 
  /// 📌 Endpoint:
  /// GET /coins/{id}/market_chart
  /// 
  /// 📌 Returns:
  /// List of [timestamp, price]
  Future<Result<List<List<dynamic>>>> getCryptoHistory({
    required String id,
    int days = 1, // 1D, 7D, 30D later
  }) async {
    try {
      // Graph endpoint: returns prices in [timestamp, price] format.
      final response = await _apiClient.dio.get(
        'coins/$id/market_chart',
        queryParameters: {
          'vs_currency': 'inr',
          'days': days,
        },
      );

      /// ✅ Extract "prices"
      return ResultSuccess(
        List<List<dynamic>>.from(response.data['prices']),
      );

    } catch (e) {
      return ResultFailure(AppFailure.fromException(e));
    }
  }
}