// File: lib/core/local/session_service.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:hive/hive.dart';

// MAUI map: This acts like a lightweight local session/auth store.
class SessionService {
  static const String _sessionBoxName = 'session';
  static const String _usersBoxName = 'users';
  static const String _currentUserKey = 'current_user_email';
  static const String _currentSessionKey = 'current_session';

  Box get _sessionBox => Hive.box(_sessionBoxName);
  Box get _usersBox => Hive.box(_usersBoxName);

  String? get currentUserEmail {
    final value = _sessionBox.get(_currentUserKey);
    return value is String ? value : null;
  }

  bool get isLoggedIn => currentUserEmail != null;

  Map<String, dynamic>? get currentSession {
    final value = _sessionBox.get(_currentSessionKey);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  void createSession({
    required String email,
    required String environment,
  }) {
    final now = DateTime.now();

    _sessionBox.put(_currentUserKey, email);
    _sessionBox.put(_currentSessionKey, {
      'email': email,
      'environment': environment,
      'loginAt': now.toIso8601String(),
      'sessionId': now.microsecondsSinceEpoch.toString(),
    });

    final existingUser = _usersBox.get(email);
    final createdAt = existingUser is Map
        ? existingUser['createdAt']?.toString() ?? now.toIso8601String()
        : now.toIso8601String();

    _usersBox.put(email, {
      'email': email,
      'createdAt': createdAt,
      'lastLoginAt': now.toIso8601String(),
      'lastEnvironment': environment,
    });
  }

  void clearSession() {
    _sessionBox.delete(_currentUserKey);
    _sessionBox.delete(_currentSessionKey);
  }
}
