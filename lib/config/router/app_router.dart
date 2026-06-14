// File: lib/config/router/app_router.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:go_router/go_router.dart';

import '../../core/local/session_service.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/navigation/presentation/main_tab_shell.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/crypto/presentation/crypto_list_screen.dart';
import '../../features/insights/presentation/insights_chat_screen.dart';
import '../../features/user/presentation/user_screen.dart';
import '../../features/crypto/presentation/screens/crypto_details_screen.dart';
import '../../features/crypto/data/models/crypto_model.dart';

// MAUI map: GoRouter is similar to Shell navigation routes in one place.

final GoRouter appRouter = GoRouter(

  initialLocation: '/', // ✅ IMPORTANT
  redirect: (context, state) {
    final sessionService = SessionService();
    final loggedIn = sessionService.isLoggedIn;
    final path = state.matchedLocation;
    final isLoginRoute = path == '/';

    if (!loggedIn && !isLoginRoute) {
      return '/';
    }

    if (loggedIn && isLoginRoute) {
      return '/home';
    }

    return null;
  },

  routes: [

    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainTabShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/market',
              builder: (context, state) => const CryptoListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/insights',
              builder: (context, state) => const InsightsChatScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/user',
              builder: (context, state) => const UserScreen(),
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/details',
      builder: (context, state) {
        final crypto = state.extra as CryptoModel;
        return CryptoDetailsScreen(crypto: crypto);
      },
    ),
  ],
);
