// File: lib/features/auth/data/repositories/auth_repository_impl.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/local/session_service.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SessionService _sessionService;

  AuthRepositoryImpl(this._sessionService);

  @override
  Future<Result<void>> login({
    required String email,
    required String environment,
  }) async {
    try {
      _sessionService.createSession(
        email: email.trim().toLowerCase(),
        environment: environment,
      );
      return const ResultSuccess(null);
    } catch (e) {
      return ResultFailure(AppFailure.fromException(e));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      _sessionService.clearSession();
      return const ResultSuccess(null);
    } catch (e) {
      return ResultFailure(AppFailure.fromException(e));
    }
  }

  @override
  bool isLoggedIn() {
    return _sessionService.isLoggedIn;
  }
}
