// File: lib/features/home/presentation/home_screen.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/notifications/price_alert_service.dart';
import '../../crypto/data/models/crypto_model.dart';
import '../../../shared/widgets/app_error_snackbar.dart';
import '../../../shared/widgets/logout_dialog.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/home_provider.dart';

// MAUI map: This screen is like Dashboard page bound to Home ViewModel.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  String _formatQuantity(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    final fixed = value.toStringAsFixed(8);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Future<void> _handleBackPressed() async {
    final shouldLogout = await _showLogoutDialog();

    if (!mounted || !shouldLogout) return;
    await ref.read(authProvider.notifier).logout();
    context.go('/');
  }

  Future<bool> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const LogoutDialog();
      },
    );

    return result ?? false;
  }

  Future<void> _openHoldingDetails(HoldingItem item) async {
    final approxPrice = item.qty > 0 ? (item.value / item.qty) : 0.0;

    final crypto = CryptoModel(
      id: item.id,
      name: item.name,
      symbol: item.symbol,
      image: item.image,
      currentPrice: approxPrice,
      priceChangePercentage: 0,
    );

    await context.push('/details', extra: crypto);
    if (!mounted) return;
    ref.read(homeProvider.notifier).loadPortfolio();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homeProvider.notifier).loadPortfolio();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);

    // MAUI map: ref.listen() is like reacting to ViewModel events (one-time side effects).
    ref.listen<HomeState>(homeProvider, (previous, next) {
      final previousMessage = previous?.failure?.message;
      final nextFailure = next.failure;

      if (nextFailure == null) return;
      if (previousMessage == nextFailure.message) return;

      showUserFriendlyError(context, failure: nextFailure);
    });

    return WillPopScope(
      // MAUI map: intercept hardware back and run custom logout confirmation.
      onWillPop: () async {
        await _handleBackPressed();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackPressed,
          ),
          title: const Text("Dashboard"),
        ),

        body: ValueListenableBuilder<bool>(
          valueListenable: PriceAlertService.instance.isCheckingPrices,
          builder: (context, isCheckingPrices, _) {
            return ValueListenableBuilder<String?>(
              valueListenable: PriceAlertService.instance.checkingMessage,
              builder: (context, checkingMessage, _) {
                final showLoader = homeState.isLoading || isCheckingPrices;
                final invested = homeState.investedPortfolio;
                final current = homeState.totalPortfolio;
                final pnl = current - invested;
                final pnlPercent = invested > 0 ? (pnl / invested) * 100 : 0.0;
                final isProfit = pnl >= 0;
                final cardGradient = isProfit
                    ? const [Color(0xFF065F46), Color(0xFF10B981)]
                    : const [Color(0xFF7F1D1D), Color(0xFFEF4444)];

                return RefreshIndicator(
                  onRefresh: () => ref.read(homeProvider.notifier).loadPortfolio(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showLoader)
                            const LinearProgressIndicator(minHeight: 2),
                          if (isCheckingPrices && checkingMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              checkingMessage,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: cardGradient,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2B0F172A),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Portfolio Snapshot',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '₹ ${current.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${isProfit ? '+' : ''}₹ ${pnl.toStringAsFixed(2)} (${isProfit ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatPill(
                                label: 'Invested',
                                value: '₹ ${invested.toStringAsFixed(2)}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatPill(
                                label: 'Current',
                                value: '₹ ${current.toStringAsFixed(2)}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatPill(
                              label: 'Assets',
                              value: '${homeState.holdings.length}',
                            ),
                            const SizedBox(width: 10),
                            _StatPill(
                              label: 'Top Holding',
                              value: homeState.holdings.isEmpty
                                  ? '--'
                                  : homeState.holdings.first.symbol
                                      .toUpperCase(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Holdings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${homeState.holdings.length} coins',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE4EAF3)),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: const [
                        _RiskLegendChip(
                          label: '1-2 Low',
                          color: Color(0xFF1D9F60),
                        ),
                        _RiskLegendChip(
                          label: '3 Medium',
                          color: Color(0xFFF59E0B),
                        ),
                        _RiskLegendChip(
                          label: '4-5 High',
                          color: Color(0xFFDC2626),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (homeState.holdings.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE7EAF0)),
                      ),
                      child: const Text(
                        'No holdings yet. Tap View Market to buy your first coin.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Column(
                      children: homeState.holdings.map((item) {
                        return _HoldingCard(
                          item: item,
                          totalPortfolio: homeState.totalPortfolio,
                          formattedQty:
                              _formatQuantity(item.qty),
                          onTap: () => _openHoldingDetails(item),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HoldingCard extends StatefulWidget {
  final HoldingItem item;
  final double totalPortfolio;
  final String formattedQty;
  final VoidCallback onTap;

  const _HoldingCard({
    required this.item,
    required this.totalPortfolio,
    required this.formattedQty,
    required this.onTap,
  });

  @override
  State<_HoldingCard> createState() => _HoldingCardState();
}

class _HoldingCardState extends State<_HoldingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  int? _riskScore;
  bool _isRiskLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _startRiskScoring();
  }

  @override
  void didUpdateWidget(covariant _HoldingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = oldWidget.item.id != widget.item.id ||
        oldWidget.item.qty != widget.item.qty ||
        oldWidget.item.value != widget.item.value ||
        oldWidget.totalPortfolio != widget.totalPortfolio;

    if (changed) {
      _startRiskScoring();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRiskScoring() async {
    setState(() {
      _isRiskLoading = true;
      _riskScore = null;
    });

    final delay = 350 + (widget.item.symbol.codeUnitAt(0) % 650);
    await Future<void>.delayed(Duration(milliseconds: delay));
    if (!mounted) return;

    final computed = _computeRiskScore();
    setState(() {
      _riskScore = computed;
      _isRiskLoading = false;
    });
  }

  int _computeRiskScore() {
    final concentration = widget.totalPortfolio <= 0
        ? 0.0
        : (widget.item.value / widget.totalPortfolio).clamp(0.0, 1.0);

    final valueBand = (widget.item.value / 50000).clamp(0.0, 1.0);
    final symbolFactor = _symbolRiskFactor(widget.item.symbol);

    final weighted = (concentration * 2.5) + (valueBand * 1.1) + (symbolFactor * 1.4);
    return weighted.round().clamp(1, 5);
  }

  double _symbolRiskFactor(String symbol) {
    final s = symbol.toLowerCase();

    const low = {'btc', 'eth'};
    const medium = {'bnb', 'sol', 'xrp', 'ada', 'dot', 'matic'};
    const high = {'doge', 'shib', 'pepe', 'wif', 'floki', 'bonk'};

    if (low.contains(s)) return 0.30;
    if (medium.contains(s)) return 0.65;
    if (high.contains(s)) return 1.0;
    return 0.78;
  }

  Color _riskColor(int score) {
    if (score <= 2) return const Color(0xFF1D9F60);
    if (score == 3) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  String _riskLabel(int score) {
    if (score <= 2) return 'Low';
    if (score == 3) return 'Moderate';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    final riskScore = _riskScore ?? 1;
    final riskColor = _riskColor(riskScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F1FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: widget.item.image.isNotEmpty
                            ? Image.network(
                                widget.item.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.currency_bitcoin,
                                  color: Color(0xFF2563EB),
                                ),
                              )
                            : const Icon(
                                Icons.currency_bitcoin,
                                color: Color(0xFF2563EB),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.formattedQty} ${widget.item.symbol.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹ ${widget.item.value.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8EDF5)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Risk Score',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF475467),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isRiskLoading
                              ? FadeTransition(
                                  key: const ValueKey('risk-loading'),
                                  opacity: Tween<double>(begin: 0.35, end: 1).animate(
                                    CurvedAnimation(
                                      parent: _pulseController,
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                  child: Container(
                                    height: 16,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(99),
                                      color: const Color(0xFFDCE3EE),
                                    ),
                                  ),
                                )
                              : Row(
                                  key: const ValueKey('risk-ready'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    5,
                                    (index) => Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(
                                        index < riskScore
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 16,
                                        color: index < riskScore
                                            ? riskColor
                                            : const Color(0xFFA8B2C4),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (!_isRiskLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            _riskLabel(riskScore),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: riskColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD5D9E2),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskLegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RiskLegendChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: color,
            size: 8,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}