// File: lib/features/crypto/domain/usecases/search_market_cryptos_usecase.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';
import '../../data/models/crypto_model.dart';
import '../repositories/crypto_repository.dart';

class SearchMarketCryptosUseCase {
  final CryptoRepository _repository;

  SearchMarketCryptosUseCase(this._repository);

  Future<Result<List<CryptoModel>>> call({
    required String query,
  }) {
    return _repository.searchCryptos(query: query);
  }
}
