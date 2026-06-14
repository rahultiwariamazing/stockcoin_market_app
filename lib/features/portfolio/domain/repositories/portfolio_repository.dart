// File: lib/features/portfolio/domain/repositories/portfolio_repository.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';
import '../../data/models/portfolio_model.dart';

abstract class PortfolioRepository {
  Future<Result<void>> addTransaction(PortfolioModel model);

  Future<Result<List<PortfolioModel>>> getTransactions();
}
