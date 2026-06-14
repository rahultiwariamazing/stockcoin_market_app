// File: lib/shared/widgets/logout_dialog.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/styles/app_text_styles.dart';

class LogoutDialog extends StatelessWidget {
  final VoidCallback? onConfirm;

  const LogoutDialog({
    super.key,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            /// Title
            Text(
              "Logout",
              style: AppTextStyles.heading,
            ),

            const SizedBox(height: AppSizes.gapMedium),

            /// Message
            Text(
              "Are you sure you want to logout?",
              style: AppTextStyles.subText,
            ),

            const SizedBox(height: AppSizes.gapLarge),

            /// Buttons
            Row(
              children: [

                /// Cancel
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text("No"),
                  ),
                ),

                const SizedBox(width: AppSizes.gapMedium),

                /// Logout (Danger)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                      onConfirm?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    child: const Text("Yes"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}