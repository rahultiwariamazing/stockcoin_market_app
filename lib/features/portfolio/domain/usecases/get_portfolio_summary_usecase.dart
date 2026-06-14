// File: lib/features/portfolio/domain/usecases/get_portfolio_summary_usecase.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';
import '../entities/portfolio_summary.dart';
import '../repositories/portfolio_repository.dart';

class GetPortfolioSummaryUseCase {
  final PortfolioRepository _repository;

  GetPortfolioSummaryUseCase(this._repository);

  Future<Result<PortfolioSummary>> call() async {
    final result = await _repository.getTransactions();

    return result.when(
      success: (transactions) {
        double total = 0;
        final Map<String, HoldingSummary> holdingsMap = {};

        for (final item in transactions) {
          final value = item.quantity * item.price;
          final current = holdingsMap[item.id] ??
              HoldingSummary(
                id: item.id,
                name: item.name,
                symbol: item.symbol,
                image: item.image,
                qty: 0,
                value: 0,
              );

          holdingsMap[item.id] = HoldingSummary(
            id: current.id,
            name: current.name,
            symbol: current.symbol,
            image: current.image.isNotEmpty ? current.image : item.image,
            qty: current.qty + item.quantity,
            value: current.value + value,
          );

          total += value;
        }

        final filtered = holdingsMap.values
            .where((item) => item.qty > 0)
            .toList();

        return ResultSuccess(
          PortfolioSummary(
            totalPortfolio: total,
            holdings: filtered,
          ),
        );
      },
      failure: (failure) => ResultFailure(failure),
    );
  }
}
