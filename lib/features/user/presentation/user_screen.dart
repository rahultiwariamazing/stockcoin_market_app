// File: lib/features/user/presentation/user_screen.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/logout_dialog.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class UserScreen extends ConsumerWidget {
  const UserScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LogoutDialog(),
    );

    if (shouldLogout != true) return;

    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async {
        await _handleLogout(context, ref);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleLogout(context, ref),
          ),
          title: const Text('User'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Page',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This is a placeholder tab for upcoming profile and settings features.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
