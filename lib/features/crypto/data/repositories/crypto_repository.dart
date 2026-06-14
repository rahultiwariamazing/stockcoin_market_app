// File: lib/features/crypto/data/repositories/crypto_repository.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../models/crypto_model.dart';
import '../services/crypto_service.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/repositories/crypto_repository.dart' as domain;

// MAUI map: Repository hides data-source details from ViewModel/provider.
// Think of this as a translator between API service payloads and typed domain models.

/// ✅ Repository Layer
/// 
/// Converts raw API → Model
class CryptoRepository implements domain.CryptoRepository {

  final CryptoService _service = CryptoService();

  Future<Result<List<CryptoModel>>> getCryptos({int page = 1}) async {
    // Step 1: ask service for raw dynamic rows.
    final result = await _service.getCryptoMarkets(page: page);

    // Step 2: map rows into strongly typed CryptoModel list.
    return result.when(
      success: (data) {
        try {
          final models = data
              .map<CryptoModel>((json) => CryptoModel.fromJson(json))
              .toList();
          return ResultSuccess(models);
        } catch (e) {
          return ResultFailure(
            AppFailure(
              type: FailureType.parsing,
              message: 'Failed to parse market data.',
              cause: e,
            ),
          );
        }
      },
      failure: (failure) => ResultFailure(failure),
    );
  }

  @override
  Future<Result<List<CryptoModel>>> getCryptosByIds({
    required List<String> ids,
  }) async {
    // Used when search endpoint gives ids and UI still needs market objects.
    final result = await _service.getCryptoMarketsByIds(ids: ids);

    return result.when(
      success: (data) {
        try {
          final models = data
              .map<CryptoModel>((json) => CryptoModel.fromJson(json))
              .toList();
          return ResultSuccess(models);
        } catch (e) {
          return ResultFailure(
            AppFailure(
              type: FailureType.parsing,
              message: 'Failed to parse market data by ids.',
              cause: e,
            ),
          );
        }
      },
      failure: (failure) => ResultFailure(failure),
    );
  }

  @override
  Future<Result<List<CryptoModel>>> searchCryptos({
    required String query,
  }) async {
    // Search pipeline is still service-driven; repository maps to typed models.
    final result = await _service.searchCryptoMarkets(query: query);

    return result.when(
      success: (data) {
        try {
          final models = data
              .map<CryptoModel>((json) => CryptoModel.fromJson(json))
              .toList();
          return ResultSuccess(models);
        } catch (e) {
          return ResultFailure(
            AppFailure(
              type: FailureType.parsing,
              message: 'Failed to parse searched market data.',
              cause: e,
            ),
          );
        }
      },
      failure: (failure) => ResultFailure(failure),
    );
  }

  @override
  Future<Result<List<List<dynamic>>>> getCryptoHistory({
    required String id,
    int days = 1,
  }) {
    // Chart payload remains raw here; provider converts into FlSpot for graph UI.
    return _service.getCryptoHistory(id: id, days: days);
  }
}
