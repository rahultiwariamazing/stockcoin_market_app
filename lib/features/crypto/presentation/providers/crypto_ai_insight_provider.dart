import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/models/ai_stock_insight.dart';
import '../../data/services/ai_apis_stock_insight_service.dart';

// MAUI mapping: This is a ViewState DTO consumed by UI.
class CryptoAiInsightState {
  // MAUI mapping: similar to IsBusy in ViewModel.
  final bool isLoading;
  // MAUI mapping: current data bound to the UI card.
  final AiStockInsight? insight;
  // MAUI mapping: typed error for user-friendly handling.
  final AppFailure? failure;

  const CryptoAiInsightState({
    required this.isLoading,
    this.insight,
    this.failure,
  });

  factory CryptoAiInsightState.initial() {
    // Initial/default UI state before any API call.
    return const CryptoAiInsightState(
      isLoading: false,
      insight: null,
      failure: null,
    );
  }

  // Immutable update helper (like creating a new ViewState snapshot).
  CryptoAiInsightState copyWith({
    bool? isLoading,
    AiStockInsight? insight,
    AppFailure? failure,
  }) {
    return CryptoAiInsightState(
      isLoading: isLoading ?? this.isLoading,
      insight: insight ?? this.insight,
      failure: failure,
    );
  }
}

// MAUI mapping: this is the ViewModel (command + state updates).
class CryptoAiInsightNotifier extends StateNotifier<CryptoAiInsightState> {
  final AiApisStockInsightService _service;

  CryptoAiInsightNotifier(this._service)
      : super(CryptoAiInsightState.initial());

  Future<void> fetchInsight({
    required String stockName,
    required double currentPrice,
    required double changePercent,
  }) async {
    // Step 1: show loading and clear previous failure.
    state = state.copyWith(
      isLoading: true,
      failure: null,
    );

    // Step 2: call service/API layer.
    final result = await _service.fetchInsight(
      stockName: stockName,
      currentPrice: currentPrice,
      changePercent: changePercent,
    );

    // Step 3: update state based on typed result.
    state = result.when(
      success: (insight) => state.copyWith(
        isLoading: false,
        insight: insight,
        failure: null,
      ),
      failure: (failure) => state.copyWith(
        isLoading: false,
        // Keep previous insight on failure; only update error.
        failure: failure,
      ),
    );
  }
}

// Riverpod registration: exposes ViewModel + ViewState to UI.
final cryptoAiInsightProvider = StateNotifierProvider<
    CryptoAiInsightNotifier, CryptoAiInsightState>(
  (ref) => CryptoAiInsightNotifier(AiApisStockInsightService()),
);
