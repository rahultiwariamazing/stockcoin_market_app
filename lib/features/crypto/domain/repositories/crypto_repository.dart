// File: lib/features/crypto/domain/repositories/crypto_repository.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';
import '../../data/models/crypto_model.dart';

abstract class CryptoRepository {
  Future<Result<List<CryptoModel>>> getCryptos({int page = 1});

  Future<Result<List<CryptoModel>>> getCryptosByIds({
    required List<String> ids,
  });

  Future<Result<List<CryptoModel>>> searchCryptos({
    required String query,
  });

  Future<Result<List<List<dynamic>>>> getCryptoHistory({
    required String id,
    int days = 1,
  });
}
