// File: lib/features/home/presentation/providers/home_provider.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../crypto/data/repositories/crypto_repository.dart';
import '../../../crypto/domain/usecases/get_market_cryptos_usecase.dart';
import '../../../portfolio/data/repositories/portfolio_repository_impl.dart';
import '../../../portfolio/data/services/portfolio_service.dart';
import '../../../portfolio/domain/usecases/get_portfolio_summary_usecase.dart';

// MAUI map: HomeNotifier is the dashboard ViewModel.

class HoldingItem {
  final String id;
  final String name;
  final String symbol;
  final String image;
  final double qty;
  final double value;

  const HoldingItem({
    required this.id,
    required this.name,
    required this.symbol,
    required this.image,
    required this.qty,
    required this.value,
  });
}

class HomeState {
  final bool isLoading;
  final double investedPortfolio;
  final double totalPortfolio;
  final List<HoldingItem> holdings;
  final String? error;
  final AppFailure? failure;

  const HomeState({
    required this.isLoading,
    required this.investedPortfolio,
    required this.totalPortfolio,
    required this.holdings,
    this.error,
    this.failure,
  });

  factory HomeState.initial() {
    return const HomeState(
      isLoading: false,
      investedPortfolio: 0,
      totalPortfolio: 0,
      holdings: [],
      error: null,
      failure: null,
    );
  }

  HomeState copyWith({
    bool? isLoading,
    double? investedPortfolio,
    double? totalPortfolio,
    List<HoldingItem>? holdings,
    String? error,
    AppFailure? failure,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      investedPortfolio: investedPortfolio ?? this.investedPortfolio,
      totalPortfolio: totalPortfolio ?? this.totalPortfolio,
      holdings: holdings ?? this.holdings,
      error: error,
      failure: failure,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final GetPortfolioSummaryUseCase _getPortfolioSummaryUseCase;
  final GetMarketCryptosUseCase _getMarketCryptosUseCase;

  HomeNotifier(
    this._getPortfolioSummaryUseCase,
    this._getMarketCryptosUseCase,
  )
      : super(HomeState.initial());

  Future<void> loadPortfolio() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      failure: null,
    );

    final result = await _getPortfolioSummaryUseCase();

    await result.when(
      success: (summary) async {
        final mapped = summary.holdings
            .map((item) => HoldingItem(
                  id: item.id,
                  name: item.name,
                  symbol: item.symbol,
                  image: item.image,
                  qty: item.qty,
                  value: item.value,
                ))
            .toList();

        state = state.copyWith(
          isLoading: false,
          investedPortfolio: summary.totalPortfolio,
          totalPortfolio: summary.totalPortfolio,
          holdings: mapped,
          error: null,
          failure: null,
        );

        await _enrichMissingHoldingImages();
      },
      failure: (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          failure: failure,
        );
      },
    );
  }

  Future<void> _enrichMissingHoldingImages() async {
    final holdingIds = state.holdings
        .map((item) => item.id)
        .toSet()
        .toList();

    if (holdingIds.isEmpty) return;

    final imageById = <String, String>{};
    final marketResult = await _getMarketCryptosUseCase(ids: holdingIds);

    marketResult.when(
      success: (coins) {
        for (final coin in coins) {
          if (coin.image.isNotEmpty) {
            imageById[coin.id] = coin.image;
          }
        }
      },
      failure: (_) {},
    );

    // Fallback for legacy records where stored `id` may be symbol-like (e.g., BTC).
    final unresolved = state.holdings
        .where((item) => !imageById.containsKey(item.id))
        .toList();

    if (unresolved.isNotEmpty) {
      final symbolToHoldingId = {
        for (final item in unresolved)
          item.symbol.toLowerCase(): item.id,
      };

      for (var page = 1; page <= 5 && symbolToHoldingId.isNotEmpty; page++) {
        final fallbackResult = await _getMarketCryptosUseCase(page: page);

        fallbackResult.when(
          success: (coins) {
            for (final coin in coins) {
              final key = coin.symbol.toLowerCase();
              final holdingId = symbolToHoldingId[key];
              if (holdingId != null && coin.image.isNotEmpty) {
                imageById[holdingId] = coin.image;
              }
            }
          },
          failure: (_) {},
        );

        symbolToHoldingId.removeWhere(
          (_, holdingId) => imageById.containsKey(holdingId),
        );
      }
    }

    final priceById = <String, double>{};
    final marketByIdsResult = await _getMarketCryptosUseCase(ids: holdingIds);

    marketByIdsResult.when(
      success: (coins) {
        for (final coin in coins) {
          priceById[coin.id] = coin.currentPrice;
        }
      },
      failure: (_) {},
    );

    if (priceById.length < holdingIds.length) {
      final unresolvedBySymbol = {
        for (final item in state.holdings)
          if (!priceById.containsKey(item.id)) item.symbol.toLowerCase(): item.id,
      };

      for (var page = 1; page <= 5 && unresolvedBySymbol.isNotEmpty; page++) {
        final fallbackResult = await _getMarketCryptosUseCase(page: page);

        fallbackResult.when(
          success: (coins) {
            for (final coin in coins) {
              final holdingId = unresolvedBySymbol[coin.symbol.toLowerCase()];
              if (holdingId != null) {
                priceById[holdingId] = coin.currentPrice;
              }
            }
          },
          failure: (_) {},
        );

        unresolvedBySymbol.removeWhere(
          (_, holdingId) => priceById.containsKey(holdingId),
        );
      }
    }

    final updatedHoldings = state.holdings
        .map((item) {
          final currentPrice = priceById[item.id];
          final currentValue = currentPrice == null ? item.value : item.qty * currentPrice;

          return HoldingItem(
            id: item.id,
            name: item.name,
            symbol: item.symbol,
            image: imageById[item.id] ?? item.image,
            qty: item.qty,
            value: currentValue,
          );
        })
        .toList();

    final currentPortfolio = updatedHoldings.fold<double>(
      0,
      (sum, item) => sum + item.value,
    );

    state = state.copyWith(
      totalPortfolio: currentPortfolio,
      holdings: updatedHoldings,
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) {
    final portfolioRepository = PortfolioRepositoryImpl(PortfolioService());
    final cryptoRepository = CryptoRepository();

    return HomeNotifier(
      GetPortfolioSummaryUseCase(portfolioRepository),
      GetMarketCryptosUseCase(cryptoRepository),
    );
  },
);
