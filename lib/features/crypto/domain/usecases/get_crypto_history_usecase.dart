// File: lib/features/crypto/domain/usecases/get_crypto_history_usecase.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';
import '../repositories/crypto_repository.dart';

class GetCryptoHistoryUseCase {
  final CryptoRepository _repository;

  GetCryptoHistoryUseCase(this._repository);

  Future<Result<List<List<dynamic>>>> call({
    required String coinId,
    int days = 1,
  }) {
    return _repository.getCryptoHistory(id: coinId, days: days);
  }
}
