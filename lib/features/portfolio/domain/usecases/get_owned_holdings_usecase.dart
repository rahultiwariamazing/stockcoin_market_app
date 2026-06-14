// File: lib/features/portfolio/domain/usecases/get_owned_holdings_usecase.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';
import '../repositories/portfolio_repository.dart';

class GetOwnedHoldingsUseCase {
  final PortfolioRepository _repository;

  GetOwnedHoldingsUseCase(this._repository);

  Future<Result<Map<String, double>>> call() async {
    final result = await _repository.getTransactions();

    return result.when(
      success: (transactions) {
        final Map<String, double> owned = {};
        for (final item in transactions) {
          owned[item.id] = (owned[item.id] ?? 0) + item.quantity;
        }

        owned.removeWhere((key, value) => value <= 0);
        return ResultSuccess(owned);
      },
      failure: (failure) => ResultFailure(failure),
    );
  }
}
