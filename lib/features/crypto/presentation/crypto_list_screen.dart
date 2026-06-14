// File: lib/features/crypto/presentation/crypto_list_screen.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; /// ✅ REQUIRED

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_error_snackbar.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/logout_dialog.dart';
import '../../../shared/widgets/crypto_list_item.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../portfolio/presentation/providers/portfolio_provider.dart';
import 'providers/crypto_provider.dart';

/// MAUI map: Market page bound to providers (acts like ViewModel state).
class CryptoListScreen extends ConsumerStatefulWidget {
  const CryptoListScreen({super.key});

  @override
  ConsumerState<CryptoListScreen> createState() =>
      _CryptoListScreenState();
}

class _CryptoListScreenState
    extends ConsumerState<CryptoListScreen> {

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  Future<void> _handleBackPressed() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LogoutDialog(),
    );

    if (!mounted || shouldLogout != true) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/');
  }

  @override
  void initState() {
    super.initState();

    /// MAUI map: Future.microtask here is similar to initial load in OnAppearing.
    Future.microtask(() =>
        ref.read(cryptoProvider.notifier).fetchCryptos());
    Future.microtask(() =>
      ref.read(portfolioProvider.notifier).loadHoldings());

    /// ✅ Pagination trigger
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        ref.read(cryptoProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final state = ref.watch(cryptoProvider);
  final portfolioState = ref.watch(portfolioProvider);

    // MAUI map: error side effects (toast/snackbar) should be in listener, not in state UI.
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

    return WillPopScope(
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
          title: const Text("Crypto Market"),
        ),

        body: Stack(
          children: [

          Column(
            children: [

              /// ✅ SEARCH
              Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _searchDebounce?.cancel();

                    if (value.trim().isEmpty) {
                      ref.read(cryptoProvider.notifier).clearSearch();
                    } else {
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 450),
                        () {
                          ref.read(cryptoProvider.notifier).search(value);
                        },
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Search crypto...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              /// ✅ ERROR UI
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              /// ✅ EMPTY STATE
              if (!state.isLoading &&
                  state.filteredList.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text("No results found"),
                  ),
                )
              else

              /// ✅ LIST
              Expanded(
                // MAUI map: ListView.builder is like virtualized item rendering.
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.padding),

                  itemCount: state.filteredList.length + 1,

                  itemBuilder: (context, index) {

                    /// ✅ Pagination loader
                    if (index == state.filteredList.length) {
                      return state.isPaginationLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child:
                                    CircularProgressIndicator(),
                              ),
                            )
                          : const SizedBox();
                    }

                    final crypto = state.filteredList[index];

                    /// ✅ ✅ NAVIGATION FIX 🔥
                    return CryptoListItem(
                      item: crypto,
                      ownedQuantity: portfolioState.ownedById[crypto.id] ?? 0,
                      onTap: () async {
                        await context.push(
                          '/details',
                          extra: crypto, // ✅ pass full object
                        );
                        if (!mounted) return;
                        ref.read(portfolioProvider.notifier).loadHoldings();
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          /// ✅ GLOBAL LOADER
          if (state.isLoading)
            const AppLoader(
              message: "Loading market data...",
            ),
          ],
        ),
      ),
    );
  }
}
