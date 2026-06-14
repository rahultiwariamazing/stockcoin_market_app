// File: lib/features/portfolio/data/repositories/portfolio_repository_impl.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../models/portfolio_model.dart';
import '../services/portfolio_service.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  final PortfolioService _service;

  PortfolioRepositoryImpl(this._service);

  @override
  Future<Result<void>> addTransaction(PortfolioModel model) async {
    try {
      _service.addTransaction(model);
      return const ResultSuccess(null);
    } catch (e) {
      return ResultFailure(AppFailure.fromException(e));
    }
  }

  @override
  Future<Result<List<PortfolioModel>>> getTransactions() async {
    try {
      final data = _service.getTransactions();
      return ResultSuccess(data);
    } catch (e) {
      return ResultFailure(AppFailure.fromException(e));
    }
  }
}
