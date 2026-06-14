// File: lib/features/home/presentation/home_screen.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

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
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
                            'Portfolio Balance',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '₹ ${homeState.totalPortfolio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
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

class _HoldingCard extends StatelessWidget {
  final HoldingItem item;
  final String formattedQty;
  final VoidCallback onTap;

  const _HoldingCard({
    required this.item,
    required this.formattedQty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.image.isNotEmpty
                        ? Image.network(
                            item.image,
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
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$formattedQty ${item.symbol.toUpperCase()}',
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
                      '₹ ${item.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
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