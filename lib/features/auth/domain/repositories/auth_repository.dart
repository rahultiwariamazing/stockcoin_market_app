// File: lib/features/auth/domain/repositories/auth_repository.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';

abstract class AuthRepository {
  Future<Result<void>> login({
    required String email,
    required String environment,
  });

  Future<Result<void>> logout();

  bool isLoggedIn();
}
