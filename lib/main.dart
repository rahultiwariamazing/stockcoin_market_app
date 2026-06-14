// File: lib/main.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/notifications/price_alert_service.dart';

// MAUI map: MaterialApp.router is similar to app shell + route host.

/// ✅ Entry point
Future<void> main() async {

  /// ✅ REQUIRED for async initialization
  WidgetsFlutterBinding.ensureInitialized();

  /// ✅ ✅ Initialize Hive (Local Storage)
  await Hive.initFlutter();

  /// ✅ ✅ Open portfolio storage box
  await Hive.openBox('portfolio');
  await Hive.openBox('session');
  await Hive.openBox('users');
  await Hive.openBox('alerts');

  await PriceAlertService.instance.initialize();
  PriceAlertService.instance.startMonitoring();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// ✅ Root App Widget
///
/// ✅ No ConsumerWidget needed (keeping your approach)
/// ✅ Router remains same (appRouter)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp.router(

      /// ✅ App name
      title: 'Crypto Tracker',

      /// ✅ Disable debug banner
      debugShowCheckedModeBanner: false,

      /// ✅ Global Theme
      theme: AppTheme.lightTheme,

      /// ✅ ✅ KEEPING YOUR EXISTING ROUTER (safe)
      routerConfig: appRouter,
    );
  }
}