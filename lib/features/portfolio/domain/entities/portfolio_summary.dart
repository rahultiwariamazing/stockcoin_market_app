// File: lib/features/portfolio/domain/entities/portfolio_summary.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

class HoldingSummary {
  final String id;
  final String name;
  final String symbol;
  final String image;
  final double qty;
  final double value;

  const HoldingSummary({
    required this.id,
    required this.name,
    required this.symbol,
    required this.image,
    required this.qty,
    required this.value,
  });
}

class PortfolioSummary {
  final double totalPortfolio;
  final List<HoldingSummary> holdings;

  const PortfolioSummary({
    required this.totalPortfolio,
    required this.holdings,
  });
}
