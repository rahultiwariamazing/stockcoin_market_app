// File: lib/features/auth/domain/usecases/logout_user_usecase.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class LogoutUserUseCase {
  final AuthRepository _repository;

  LogoutUserUseCase(this._repository);

  Future<Result<void>> call() {
    return _repository.logout();
  }
}
