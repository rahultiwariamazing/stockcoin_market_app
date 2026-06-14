// File: lib/features/crypto/presentation/providers/crypto_provider.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/repositories/crypto_repository.dart';
import '../../data/models/crypto_model.dart';
import '../../domain/usecases/get_crypto_history_usecase.dart';
import '../../domain/usecases/get_market_cryptos_usecase.dart';
import '../../domain/usecases/search_market_cryptos_usecase.dart';

// MAUI map: This provider is the screen ViewModel for market + chart.
// UI calls methods here; this class owns state transitions and async orchestration.

/// ✅ Crypto Provider (ViewModel)
/// Extended with:
/// - Graph data ✅
/// - Time filters ✅
class CryptoNotifier extends StateNotifier<CryptoState> {

  final GetMarketCryptosUseCase _getMarketCryptosUseCase;
  final GetCryptoHistoryUseCase _getCryptoHistoryUseCase;
  final SearchMarketCryptosUseCase _searchMarketCryptosUseCase;

  CryptoNotifier({
    required GetMarketCryptosUseCase getMarketCryptosUseCase,
    required GetCryptoHistoryUseCase getCryptoHistoryUseCase,
      required SearchMarketCryptosUseCase searchMarketCryptosUseCase,
  })  : _getMarketCryptosUseCase = getMarketCryptosUseCase,
        _getCryptoHistoryUseCase = getCryptoHistoryUseCase,
      _searchMarketCryptosUseCase = searchMarketCryptosUseCase,
        super(CryptoState.initial());

  int _page = 1;
  // Active text query and request id are used to avoid stale search responses.
  String _activeQuery = '';
  int _searchRequestId = 0;
  // Guards for chart polling/rate-limit protection.
  bool _isChartRequestInFlight = false;
  DateTime? _chartCooldownUntil;
  Duration _chartBackoff = const Duration(seconds: 10);
  static const int _maxChartBackoffSeconds = 120;
  final Map<String, List<CryptoModel>> _searchCache = {};

  bool _isRateLimitFailure(AppFailure failure) {
    final message = failure.message.toLowerCase();
    return message.contains('(429)') ||
        message.contains('rate limit');
  }

  void _applyChartRateLimitCooldown() {
    final now = DateTime.now();
    _chartCooldownUntil = now.add(_chartBackoff);

    final doubled = _chartBackoff.inSeconds * 2;
    final nextSeconds = doubled > _maxChartBackoffSeconds
        ? _maxChartBackoffSeconds
        : doubled;
    _chartBackoff = Duration(seconds: nextSeconds);
  }

  void _resetChartRateLimitState() {
    _chartCooldownUntil = null;
    _chartBackoff = const Duration(seconds: 10);
  }

  /// ✅ Load initial data (UNCHANGED ✅)
  Future<void> fetchCryptos() async {
    // MAUI mapping: set IsBusy=true and clear old error before fetching.
    state = state.copyWith(
      isLoading: true,
      error: null,
      failure: null,
    );

    final result = await _getMarketCryptosUseCase(page: _page);

    state = result.when(
      success: (data) => state.copyWith(
        isLoading: false,
        cryptoList: data,
        filteredList: data,
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

  /// ✅ Pagination (UNCHANGED ✅)
  Future<void> loadMore() async {
    // Pagination is disabled while search is active or another page load is running.
    if (_activeQuery.isNotEmpty) return;
    if (state.isPaginationLoading) return;

    state = state.copyWith(
      isPaginationLoading: true,
      error: null,
      failure: null,
    );

    final nextPage = _page + 1;
    final result = await _getMarketCryptosUseCase(page: nextPage);

    state = result.when(
      success: (data) {
        final updated = [...state.cryptoList, ...data];
        // Commit page increment only after success.
        _page = nextPage;

        return state.copyWith(
          cryptoList: updated,
          filteredList: updated,
          isPaginationLoading: false,
          error: null,
          failure: null,
        );
      },
      failure: (failure) => state.copyWith(
        isPaginationLoading: false,
        error: failure.message,
        failure: failure,
      ),
    );
  }

  /// ✅ Search (UNCHANGED ✅)
  Future<void> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    // Avoid hitting public API aggressively for single-character queries.
    if (trimmed.length < 2) {
      state = state.copyWith(
        isLoading: false,
        filteredList: _localFilter(trimmed),
        error: null,
        failure: null,
      );
      return;
    }

    _activeQuery = trimmed;
    // Token-based guard: only latest request updates UI state.
    final requestId = ++_searchRequestId;

    final cached = _searchCache[trimmed.toLowerCase()];
    if (cached != null) {
      state = state.copyWith(
        isLoading: false,
        filteredList: cached,
        error: null,
        failure: null,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      failure: null,
    );

    final result = await _searchMarketCryptosUseCase(query: trimmed);
    // Ignore stale response when user typed a newer query.
    if (requestId != _searchRequestId) return;

    state = result.when(
      success: (data) {
        _searchCache[trimmed.toLowerCase()] = data;
        return state.copyWith(
          isLoading: false,
          filteredList: data,
          error: null,
          failure: null,
        );
      },
      failure: (failure) {
        // CoinGecko free tier rate limit: gracefully fallback to local results.
        if (failure.message.contains('(429)')) {
          return state.copyWith(
            isLoading: false,
            filteredList: _localFilter(trimmed),
            error: null,
            failure: null,
          );
        }

        return state.copyWith(
          isLoading: false,
          filteredList: const [],
          error: failure.message,
          failure: failure,
        );
      },
    );
  }

  /// ✅ Clear search (UNCHANGED ✅)
  void clearSearch() {
    // Reset search mode and return to full market list.
    _activeQuery = '';
    _searchRequestId++;
    state = state.copyWith(
      isLoading: false,
      filteredList: state.cryptoList,
      error: null,
      failure: null,
    );
  }

  List<CryptoModel> _localFilter(String query) {
    final q = query.toLowerCase();
    return state.cryptoList.where((item) {
      return item.name.toLowerCase().contains(q) ||
          item.symbol.toLowerCase().contains(q);
    }).toList();
  }

  /// ✅ Refresh (UNCHANGED ✅)
  Future<void> refresh() async {
    // If searching, refresh means re-run search; otherwise reload page 1 market list.
    if (_activeQuery.isNotEmpty) {
      await search(_activeQuery);
      return;
    }

    _page = 1;
    await fetchCryptos();
  }

  // ✅ ✅ ✅ NEW — FETCH GRAPH DATA
  Future<void> fetchChartData({
    required String coinId,
    int days = 1,
    bool showLoading = true,
  }) async {
    // Cooldown guard for rate-limited API windows.
    final now = DateTime.now();
    if (_chartCooldownUntil != null) {
      if (now.isBefore(_chartCooldownUntil!)) {
        return;
      }
      _chartCooldownUntil = null;
    }

    if (_isChartRequestInFlight) return;
    _isChartRequestInFlight = true;

    if (showLoading) {
      state = state.copyWith(
        isChartLoading: true,
        error: null,
        failure: null,
      );
    }

    try {
      final result = await _getCryptoHistoryUseCase(
        coinId: coinId,
        days: days,
      );

      state = result.when(
        success: (rawData) {
          // Convert raw [timestamp, price] rows into chart spots expected by fl_chart.
          final spots = rawData
              .asMap()
              .entries
              .map((entry) => FlSpot(
                    entry.key.toDouble(),
                    (entry.value[1] as num).toDouble(),
                  ))
              .toList();

          return state.copyWith(
            chartData: spots,
            isChartLoading: false,
            selectedDays: days,
            error: null,
            failure: null,
          );
        },
        failure: (failure) {
          // For 429, apply backoff and keep UI calm during background refreshes.
          if (_isRateLimitFailure(failure)) {
            _applyChartRateLimitCooldown();

            if (!showLoading) {
              return state.copyWith(
                isChartLoading: false,
              );
            }
          }

          return state.copyWith(
            isChartLoading: false,
            error: failure.message,
            failure: failure,
          );
        },
      );

      if (!state.isChartLoading && state.failure == null) {
        _resetChartRateLimitState();
      }
    } finally {
      _isChartRequestInFlight = false;
    }
  }
}

/// ✅ State
class CryptoState {

  // Full market list and currently shown list (search can change shown subset).

  final List<CryptoModel> cryptoList;
  final List<CryptoModel> filteredList;

  final bool isLoading;
  final bool isPaginationLoading;

  final String? error;
  final AppFailure? failure;

  /// ✅ NEW (GRAPH)
  final List<FlSpot> chartData;
  final bool isChartLoading;
  final int selectedDays;

  CryptoState({
    required this.cryptoList,
    required this.filteredList,
    required this.isLoading,
    required this.isPaginationLoading,
    this.error,
    this.failure,
    required this.chartData,
    required this.isChartLoading,
    required this.selectedDays,
  });

  factory CryptoState.initial() {
    return CryptoState(
      cryptoList: [],
      filteredList: [],
      isLoading: false,
      isPaginationLoading: false,
      error: null,
      failure: null,

      /// ✅ NEW defaults
      chartData: [],
      isChartLoading: false,
      selectedDays: 1,
    );
  }

  CryptoState copyWith({
    List<CryptoModel>? cryptoList,
    List<CryptoModel>? filteredList,
    bool? isLoading,
    bool? isPaginationLoading,
    String? error,
    AppFailure? failure,

    List<FlSpot>? chartData,
    bool? isChartLoading,
    int? selectedDays,
  }) {
    // Immutable state update pattern (same idea as replacing a MAUI ViewState snapshot).
    return CryptoState(
      cryptoList: cryptoList ?? this.cryptoList,
      filteredList: filteredList ?? this.filteredList,
      isLoading: isLoading ?? this.isLoading,
      isPaginationLoading:
          isPaginationLoading ?? this.isPaginationLoading,
      error: error ?? this.error,
        failure: failure,

      chartData: chartData ?? this.chartData,
      isChartLoading: isChartLoading ?? this.isChartLoading,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }
}

/// ✅ Provider
final cryptoProvider =
StateNotifierProvider<CryptoNotifier, CryptoState>(
  (ref) {
    // Manual DI wiring: repository -> use cases -> notifier.
    final repository = CryptoRepository();
    return CryptoNotifier(
      getMarketCryptosUseCase: GetMarketCryptosUseCase(repository),
      getCryptoHistoryUseCase: GetCryptoHistoryUseCase(repository),
      searchMarketCryptosUseCase: SearchMarketCryptosUseCase(repository),
    );
  },
);