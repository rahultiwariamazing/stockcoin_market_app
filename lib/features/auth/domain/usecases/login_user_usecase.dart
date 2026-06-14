// File: lib/features/auth/domain/usecases/login_user_usecase.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class LoginUserUseCase {
  final AuthRepository _repository;

  LoginUserUseCase(this._repository);

  Future<Result<void>> call({
    required String email,
    required String environment,
  }) {
    return _repository.login(email: email, environment: environment);
  }
}
