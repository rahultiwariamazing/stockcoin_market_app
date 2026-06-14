// File: lib/features/portfolio/presentation/providers/portfolio_provider.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../crypto/data/models/crypto_model.dart';
import '../../data/repositories/portfolio_repository_impl.dart';
import '../../data/models/portfolio_model.dart';
import '../../data/services/portfolio_service.dart';
import '../../domain/usecases/add_portfolio_transaction_usecase.dart';
import '../../domain/usecases/get_owned_holdings_usecase.dart';

// MAUI map: PortfolioNotifier is the transaction/holdings ViewModel.

class PortfolioState {
  final Map<String, double> ownedById;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final AppFailure? failure;

  const PortfolioState({
    required this.ownedById,
    required this.isLoading,
    required this.isSaving,
    this.error,
    this.failure,
  });

  factory PortfolioState.initial() {
    return const PortfolioState(
      ownedById: {},
      isLoading: false,
      isSaving: false,
      error: null,
      failure: null,
    );
  }

  PortfolioState copyWith({
    Map<String, double>? ownedById,
    bool? isLoading,
    bool? isSaving,
    String? error,
    AppFailure? failure,
  }) {
    return PortfolioState(
      ownedById: ownedById ?? this.ownedById,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      failure: failure,
    );
  }
}

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  final GetOwnedHoldingsUseCase _getOwnedHoldingsUseCase;
  final AddPortfolioTransactionUseCase _addPortfolioTransactionUseCase;

  PortfolioNotifier({
    required GetOwnedHoldingsUseCase getOwnedHoldingsUseCase,
    required AddPortfolioTransactionUseCase addPortfolioTransactionUseCase,
  })  : _getOwnedHoldingsUseCase = getOwnedHoldingsUseCase,
        _addPortfolioTransactionUseCase = addPortfolioTransactionUseCase,
        super(PortfolioState.initial());

  Future<void> loadHoldings() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      failure: null,
    );

    final result = await _getOwnedHoldingsUseCase();

    state = result.when(
      success: (owned) => state.copyWith(
        ownedById: owned,
        isLoading: false,
        error: null,
        failure: null,
      ),
      failure: (failure) => state.copyWith(
        isLoading: false,
        error: failure.message,
        failure: failure,
      ),
    );
  }

  double ownedQuantityFor(String coinId) {
    return state.ownedById[coinId] ?? 0;
  }

  Future<void> buy({
    required CryptoModel crypto,
    required int quantity,
  }) async {
    if (quantity <= 0) return;

    state = state.copyWith(
      isSaving: true,
      error: null,
      failure: null,
    );

    try {
      final model = PortfolioModel(
        id: crypto.id,
        name: crypto.name,
        symbol: crypto.symbol,
        image: crypto.image,
        price: crypto.currentPrice,
        quantity: quantity.toDouble(),
        date: DateTime.now(),
      );

      final result = await _addPortfolioTransactionUseCase(model);
      if (result is ResultFailure<void>) {
        state = state.copyWith(
          isSaving: false,
          error: result.failure.message,
          failure: result.failure,
        );
        return;
      }

      await loadHoldings();
      state = state.copyWith(isSaving: false);
    } catch (e) {
      final failure = AppFailure.fromException(e);
      state = state.copyWith(
        isSaving: false,
        error: failure.message,
        failure: failure,
      );
    }
  }

  Future<AppFailure?> sell({
    required CryptoModel crypto,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return const AppFailure(
        type: FailureType.validation,
        message: 'Enter valid whole number quantity',
      );
    }

    final owned = ownedQuantityFor(crypto.id);
    if (quantity > owned) {
      return AppFailure(
        type: FailureType.validation,
        message: 'You only own ${_formatQuantity(owned)} ${crypto.symbol.toUpperCase()}',
      );
    }

    state = state.copyWith(
      isSaving: true,
      error: null,
      failure: null,
    );

    try {
      final model = PortfolioModel(
        id: crypto.id,
        name: crypto.name,
        symbol: crypto.symbol,
        image: crypto.image,
        price: crypto.currentPrice,
        quantity: -quantity.toDouble(),
        date: DateTime.now(),
      );

      final result = await _addPortfolioTransactionUseCase(model);
      if (result is ResultFailure<void>) {
        state = state.copyWith(
          isSaving: false,
          error: result.failure.message,
          failure: result.failure,
        );
        return result.failure;
      }

      await loadHoldings();
      state = state.copyWith(isSaving: false);
      return null;
    } catch (e) {
      final failure = AppFailure.fromException(e);
      state = state.copyWith(
        isSaving: false,
        error: failure.message,
        failure: failure,
      );
      return failure;
    }
  }

  String _formatQuantity(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    final fixed = value.toStringAsFixed(8);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, PortfolioState>(
  (ref) {
    final repository = PortfolioRepositoryImpl(PortfolioService());
    return PortfolioNotifier(
      getOwnedHoldingsUseCase: GetOwnedHoldingsUseCase(repository),
      addPortfolioTransactionUseCase:
          AddPortfolioTransactionUseCase(repository),
    );
  },
);
