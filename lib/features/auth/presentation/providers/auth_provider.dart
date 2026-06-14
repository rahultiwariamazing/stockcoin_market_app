// File: lib/features/auth/presentation/providers/auth_provider.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/local/session_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_user_usecase.dart';
import '../../domain/usecases/logout_user_usecase.dart';

// MAUI map: StateNotifier + state class works like ViewModel + UI state model.

/// ✅ State class (like ViewModel state in MAUI)
class AuthState {

  final bool isLoading;
  final String message;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.message = "",
    this.error,
  });

  /// ✅ Copy method (immutable update)
  AuthState copyWith({
    bool? isLoading,
    String? message,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      error: error,
    );
  }
}

/// ✅ ViewModel (Riverpod Notifier)
class AuthNotifier extends StateNotifier<AuthState> {

  late final LoginUserUseCase _loginUserUseCase;
  late final LogoutUserUseCase _logoutUserUseCase;

  AuthNotifier() : super(const AuthState()) {
    final repository = AuthRepositoryImpl(SessionService());
    _loginUserUseCase = LoginUserUseCase(repository);
    _logoutUserUseCase = LogoutUserUseCase(repository);
  }

  /// ✅ Login logic moved here
  Future<void> login({
    required String email,
    required String environment,
  }) async {

    state = state.copyWith(
      isLoading: true,
      message: "Checking authorization...",
      error: null,
    );

    await Future.delayed(const Duration(seconds: 2));

    final result = await _loginUserUseCase(
      email: email,
      environment: environment,
    );

    if (result is ResultFailure<void>) {
      state = state.copyWith(
        isLoading: false,
        message: "",
        error: result.failure.message,
      );
      return;
    }

    state = state.copyWith(
      message: "Login successful...",
    );

    await Future.delayed(const Duration(seconds: 1));

    state = state.copyWith(
      isLoading: false,
    );
  }

  Future<void> logout() async {
    await _logoutUserUseCase();
    state = const AuthState();
  }
}

/// ✅ Provider (used in UI)
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
