// File: lib/features/portfolio/domain/usecases/get_portfolio_transactions_usecase.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';
import '../../data/models/portfolio_model.dart';
import '../repositories/portfolio_repository.dart';

class GetPortfolioTransactionsUseCase {
  final PortfolioRepository _repository;

  GetPortfolioTransactionsUseCase(this._repository);

  Future<Result<List<PortfolioModel>>> call() {
    return _repository.getTransactions();
  }
}
