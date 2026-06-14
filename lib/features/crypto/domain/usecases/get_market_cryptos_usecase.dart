// File: lib/features/crypto/domain/usecases/get_market_cryptos_usecase.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';
import '../../data/models/crypto_model.dart';
import '../repositories/crypto_repository.dart';

class GetMarketCryptosUseCase {
  final CryptoRepository _repository;

  GetMarketCryptosUseCase(this._repository);

  Future<Result<List<CryptoModel>>> call({
    int page = 1,
    List<String>? ids,
  }) {
    if (ids != null) {
      return _repository.getCryptosByIds(ids: ids);
    }
    return _repository.getCryptos(page: page);
  }
}
