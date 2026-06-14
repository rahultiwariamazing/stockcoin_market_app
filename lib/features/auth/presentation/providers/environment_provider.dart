// File: lib/features/auth/presentation/providers/environment_provider.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ✅ Environment Provider (DEV / QA / PROD)
///
/// Used for:
/// - Switching API env later
/// - Debugging / config selection
final environmentProvider = StateProvider<String>((ref) {
  return "DEV"; // ✅ Default environment
});
