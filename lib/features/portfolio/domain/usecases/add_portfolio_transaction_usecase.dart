// File: lib/features/portfolio/domain/usecases/add_portfolio_transaction_usecase.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';
import '../../data/models/portfolio_model.dart';
import '../repositories/portfolio_repository.dart';

class AddPortfolioTransactionUseCase {
  final PortfolioRepository _repository;

  AddPortfolioTransactionUseCase(this._repository);

  Future<Result<void>> call(PortfolioModel model) {
    return _repository.addTransaction(model);
  }
}
