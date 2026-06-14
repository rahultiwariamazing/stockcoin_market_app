// File: lib/shared/widgets/app_error_snackbar.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';

// MAUI map: Similar to a centralized toast/snackbar helper service.

void showUserFriendlyError(
  BuildContext context, {
  AppFailure? failure,
  String? fallbackMessage,
}) {
  final message = _resolveMessage(failure, fallbackMessage);
  if (message == null || message.trim().isEmpty) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}

String? _resolveMessage(AppFailure? failure, String? fallbackMessage) {
  if (failure != null) {
    switch (failure.type) {
      case FailureType.network:
        return 'Unable to connect. Please check your internet and try again.';
      case FailureType.timeout:
        return 'Request is taking too long. Please try again.';
      case FailureType.server:
        return 'Server is busy right now. Please try again in a moment.';
      case FailureType.storage:
        return 'Could not access local data. Please try again.';
      case FailureType.validation:
        return failure.message;
      case FailureType.parsing:
        return 'Unexpected response received. Please refresh and try again.';
      case FailureType.unknown:
        return failure.message;
    }
  }

  return fallbackMessage;
}
