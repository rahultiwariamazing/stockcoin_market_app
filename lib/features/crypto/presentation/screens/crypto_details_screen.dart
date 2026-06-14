// File: lib/features/crypto/presentation/screens/crypto_details_screen.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/animations/trade_particle_flight.dart';
import '../../../../shared/widgets/app_error_snackbar.dart';

import '../../data/models/ai_stock_insight.dart';
import '../../data/models/crypto_model.dart';
import '../providers/crypto_ai_insight_provider.dart';
import '../providers/crypto_provider.dart';
import '../../../portfolio/presentation/providers/portfolio_provider.dart';

// MAUI map: Details page combines two ViewModel-like providers (market + portfolio).
class CryptoDetailsScreen extends ConsumerStatefulWidget {

  final CryptoModel crypto;

  const CryptoDetailsScreen({
    super.key,
    required this.crypto,
  });

  @override
  ConsumerState<CryptoDetailsScreen> createState() =>
      _CryptoDetailsScreenState();
}

class _CryptoDetailsScreenState
    extends ConsumerState<CryptoDetailsScreen> with TickerProviderStateMixin {

  static const Duration _chartRefreshInterval = Duration(seconds: 120);
  Timer? _chartRefreshTimer;
  final GlobalKey _badgeKey = GlobalKey();
  final GlobalKey _buyButtonKey = GlobalKey();
  final GlobalKey _sellButtonKey = GlobalKey();
  final TradeParticleFlight _tradeParticleFlight = const TradeParticleFlight();
  late final AnimationController _badgeBounceController;
  late final Animation<double> _badgeScaleAnimation;
  late final Animation<double> _badgeGlowAnimation;

  String _formatQuantity(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    final fixed = value.toStringAsFixed(8);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatYAxis(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildBottomAxisTitle(
    double value,
    TitleMeta meta,
    int selectedDays,
    int totalPoints,
  ) {
    if (totalPoints <= 1) {
      return const SizedBox.shrink();
    }

    final int index = value.round();
    final int mid = totalPoints ~/ 2;
    final int last = totalPoints - 1;

    String? label;
    if (index == 0) {
      label = 'Start';
    } else if (index == mid) {
      label = selectedDays == 1
          ? '12h'
          : selectedDays == 7
              ? 'Day 4'
              : 'Day 15';
    } else if (index == last) {
      label = selectedDays == 1 ? '24h' : '${selectedDays}d';
    }

    if (label == null) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _badgeBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _badgeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.22, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_badgeBounceController);
    _badgeGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _badgeBounceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    Future.microtask(() {
      _fetchChartData(days: 1);
      _fetchAiInsight();
      ref.read(portfolioProvider.notifier).loadHoldings();
      _startChartAutoRefresh();
    });
  }

  @override
  void dispose() {
    _chartRefreshTimer?.cancel();
    _badgeBounceController.dispose();
    super.dispose();
  }

  Future<void> _runTradeAnimation({required bool isBuy}) async {
    final sourceKey = isBuy ? _buyButtonKey : _sellButtonKey;

    if (isBuy) {
      await _tradeParticleFlight.triggerBuyAnimation(
        context,
        sourceKey: sourceKey,
        targetKey: _badgeKey,
        onReached: _animateBadge,
      );
      return;
    }

    await _tradeParticleFlight.triggerSellAnimation(
      context,
      sourceKey: sourceKey,
      targetKey: _badgeKey,
      onReached: _animateBadge,
    );
  }

  void _animateBadge() {
    if (!mounted) return;
    _badgeBounceController.forward(from: 0);
  }

  void _startChartAutoRefresh() {
    _chartRefreshTimer?.cancel();
    _chartRefreshTimer = Timer.periodic(_chartRefreshInterval, (_) {
      if (!mounted) return;

      final selectedDays = ref.read(cryptoProvider).selectedDays;
      if (selectedDays != 1) return;

      _fetchChartData(showLoading: false);
    });
  }

  Future<void> _fetchChartData({
    int? days,
    bool showLoading = true,
  }) async {
    final selectedDays =
        days ?? ref.read(cryptoProvider).selectedDays;

    await ref.read(cryptoProvider.notifier).fetchChartData(
      coinId: widget.crypto.id,
      days: selectedDays,
      showLoading: showLoading,
    );
  }

  Future<void> _fetchAiInsight() async {
    final crypto = widget.crypto;

    await ref.read(cryptoAiInsightProvider.notifier).fetchInsight(
      stockName: crypto.name,
      currentPrice: crypto.currentPrice,
      changePercent: crypto.priceChangePercentage,
    );
  }

  @override
  Widget build(BuildContext context) {

    final crypto = widget.crypto;
    final state = ref.watch(cryptoProvider);
    final aiState = ref.watch(cryptoAiInsightProvider);
    final portfolioState = ref.watch(portfolioProvider);
    final ownedQuantity = portfolioState.ownedById[crypto.id] ?? 0;
    final canSell = ownedQuantity > 0;

    // MAUI map: listeners are for one-time effects like popups; watch is for UI binding.
    ref.listen<CryptoState>(cryptoProvider, (previous, next) {
      final previousMessage = previous?.failure?.message;
      final nextFailure = next.failure;

      if (nextFailure == null) return;
      if (previousMessage == nextFailure.message) return;

      showUserFriendlyError(context, failure: nextFailure);
    });

    ref.listen<PortfolioState>(portfolioProvider, (previous, next) {
      final previousMessage = previous?.failure?.message;
      final nextFailure = next.failure;

      if (nextFailure == null) return;
      if (previousMessage == nextFailure.message) return;

      showUserFriendlyError(context, failure: nextFailure);
    });

    ref.listen<CryptoAiInsightState>(cryptoAiInsightProvider, (previous, next) {
      final previousMessage = previous?.failure?.message;
      final nextFailure = next.failure;

      if (nextFailure == null) return;
      if (previousMessage == nextFailure.message) return;

      showUserFriendlyError(context, failure: nextFailure);
    });

    final isPositive =
        crypto.priceChangePercentage >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(crypto.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedBuilder(
              animation: _badgeBounceController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _badgeScaleAnimation.value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6)
                              .withOpacity(0.22 * _badgeGlowAnimation.value),
                          blurRadius: 14 * _badgeGlowAnimation.value,
                          spreadRadius: 2 * _badgeGlowAnimation.value,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: Stack(
                key: _badgeKey,
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        _formatQuantity(ownedQuantity),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 22,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE9F1FF),
                        backgroundImage: crypto.image.isNotEmpty
                            ? NetworkImage(crypto.image)
                            : null,
                        radius: 28,
                        child: crypto.image.isEmpty
                            ? const Icon(
                                Icons.currency_bitcoin,
                                color: Color(0xFF2563EB),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crypto.name,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              crypto.symbol.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _fetchAiInsight,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        color: Colors.white,
                        tooltip: 'Refresh AI insight',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '₹ ${crypto.currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 34,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTrendPill(crypto.priceChangePercentage),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildFilter('1D', 1),
                      const SizedBox(width: 8),
                      _buildFilter('7D', 7),
                      const SizedBox(width: 8),
                      _buildFilter('1M', 30),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: state.isChartLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : state.chartData.isEmpty
                            ? const Center(
                                child: Text(
                                  'No chart data available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) =>
                                        const FlLine(
                                      color: Color(0xFFEAEAEA),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: (() {
                                          final yValues = state.chartData
                                              .map((e) => e.y)
                                              .toList();
                                          final minY = yValues.reduce(
                                            (a, b) => a < b ? a : b,
                                          );
                                          final maxY = yValues.reduce(
                                            (a, b) => a > b ? a : b,
                                          );
                                          final diff =
                                              (maxY - minY).abs();
                                          return (diff == 0
                                                  ? 1
                                                  : diff / 3)
                                              .toDouble();
                                        })(),
                                        reservedSize: 44,
                                        getTitlesWidget: (value, meta) =>
                                            Text(
                                          _formatYAxis(value),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 24,
                                        getTitlesWidget: (value, meta) =>
                                            _buildBottomAxisTitle(
                                          value,
                                          meta,
                                          state.selectedDays,
                                          state.chartData.length,
                                        ),
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      isCurved: true,
                                      color: isPositive
                                          ? AppColors.success
                                          : AppColors.error,
                                      barWidth: 3,
                                      dotData:
                                          const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: (isPositive
                                                ? AppColors.success
                                                : AppColors.error)
                                            .withOpacity(0.2),
                                      ),
                                      spots: state.chartData,
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAiInsightCard(aiState),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: _buyButtonKey,
                    onPressed: () => _openTransactionDialog(
                      context,
                      crypto,
                      true,
                      ownedQuantity,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('Buy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: _sellButtonKey,
                    onPressed: canSell
                        ? () => _openTransactionDialog(
                              context,
                              crypto,
                              false,
                              ownedQuantity,
                            )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('Sell'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendPill(double changePercent) {
    final isPositive = changePercent >= 0;
    final color = isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            '${changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard(CryptoAiInsightState aiState) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      builder: (context, opacity, child) => Opacity(
        opacity: opacity,
        child: child,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'AI Insight',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _fetchAiInsight,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh insight',
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: aiState.isLoading
                  ? const _AiInsightShimmer()
                  : aiState.failure != null
                      ? Column(
                          key: const ValueKey('ai-error'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Could not load AI insight right now.',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _fetchAiInsight,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try again'),
                            ),
                          ],
                        )
                      : _AiInsightContent(
                          key: const ValueKey('ai-success'),
                          insight: aiState.insight ?? AiStockInsight.fallback(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ FILTER
  Widget _buildFilter(String label, int days) {

    final state = ref.watch(cryptoProvider);
    final isSelected = state.selectedDays == days;

    return GestureDetector(
      onTap: () {
        _fetchChartData(days: days);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  /// ✅ ✅ BUY / SELL DIALOG (UPDATED with Hive)
  void _openTransactionDialog(
      BuildContext context,
      CryptoModel crypto,
      bool isBuy,
      double availableQuantity) {

    // MAUI map: showDialog is similar to opening a modal popup page.
    final portfolioNotifier = ref.read(portfolioProvider.notifier);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {

        return AlertDialog(
          title: Text(isBuy ? "Buy ${crypto.symbol.toUpperCase()}" : "Sell ${crypto.symbol.toUpperCase()}"),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter quantity of ${crypto.symbol.toUpperCase()} (coin units, not INR amount)",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              if (!isBuy) ...[
                const SizedBox(height: 8),
                Text(
                  "Available: ${_formatQuantity(availableQuantity)} ${crypto.symbol.toUpperCase()}",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: "Quantity",
                  hintText: "e.g. 5",
                  suffixText: crypto.symbol.toUpperCase(),
                ),
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {

                final quantityInt = int.tryParse(controller.text);
                final quantity = quantityInt;

                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content:
                          Text("Enter valid whole number quantity"),
                    ),
                  );
                  return;
                }

                if (isBuy) {
                  await portfolioNotifier.buy(
                    crypto: crypto,
                    quantity: quantity,
                  );
                } else {
                  final failure = await portfolioNotifier.sell(
                    crypto: crypto,
                    quantity: quantity,
                  );

                  if (failure != null && mounted) {
                    showUserFriendlyError(context, failure: failure);
                    return;
                  }
                }

                Navigator.pop(dialogContext);

                if (mounted) {
                  _runTradeAnimation(isBuy: isBuy);
                }

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      isBuy
                          ? "Bought successfully"
                          : "Sold successfully",
                    ),
                  ),
                );
              },
              child: Text(isBuy ? "Buy" : "Sell"),
            ),
          ],
        );
      },
    );
  }
}

class _AiInsightContent extends StatelessWidget {
  final AiStockInsight insight;

  const _AiInsightContent({
    super.key,
    required this.insight,
  });

  Color _recommendationColor(RecommendationType recommendation) {
    switch (recommendation) {
      case RecommendationType.buy:
        return const Color(0xFF16A34A);
      case RecommendationType.hold:
        return const Color(0xFFF59E0B);
      case RecommendationType.avoid:
        return const Color(0xFFDC2626);
    }
  }

  String _recommendationLabel(RecommendationType recommendation) {
    switch (recommendation) {
      case RecommendationType.buy:
        return 'Buy';
      case RecommendationType.hold:
        return 'Hold';
      case RecommendationType.avoid:
        return 'Avoid';
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendationColor = _recommendationColor(insight.recommendation);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Market Explanation',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          insight.marketExplanation,
          style: const TextStyle(
            height: 1.45,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Recommendation',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: recommendationColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: recommendationColor.withOpacity(0.45)),
          ),
          child: Text(
            _recommendationLabel(insight.recommendation),
            style: TextStyle(
              color: recommendationColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          insight.disclaimer,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _AiInsightShimmer extends StatefulWidget {
  const _AiInsightShimmer();

  @override
  State<_AiInsightShimmer> createState() => _AiInsightShimmerState();
}

class _AiInsightShimmerState extends State<_AiInsightShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      key: const ValueKey('ai-loading'),
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.2 + (_controller.value * 0.25);
        final color = Color(0xFF94A3B8).withOpacity(alpha);

        Widget block({double? width, double height = 12}) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(width: 160, height: 14),
            const SizedBox(height: 10),
            block(height: 12),
            const SizedBox(height: 8),
            block(height: 12),
            const SizedBox(height: 8),
            block(width: MediaQuery.of(context).size.width * 0.5, height: 12),
            const SizedBox(height: 16),
            block(width: 120, height: 14),
            const SizedBox(height: 8),
            block(width: 80, height: 30),
          ],
        );
      },
    );
  }
}