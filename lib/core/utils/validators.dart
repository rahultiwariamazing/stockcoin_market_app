// File: lib/core/utils/validators.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

/// ✅ Common Validators (Reusable across app)
///
/// MAUI equivalent:
/// Validation helper / service class
class Validators {

  /// ✅ Email validation
  static String? validateEmail(String? value) {

    if (value == null || value.isEmpty) {
      return "Enter email";
    }

    final emailRegex = RegExp(
      r'^[\w\.-]+@([\w\-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return "Enter valid email";
    }

    return null;
  }

  /// ✅ Password validation
  static String? validatePassword(String? value) {

    if (value == null || value.isEmpty) {
      return "Enter password";
    }

    if (value.length < 6) {
      return "Min 6 characters";
    }

    return null;
  }
}