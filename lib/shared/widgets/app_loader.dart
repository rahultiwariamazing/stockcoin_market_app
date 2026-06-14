// File: lib/shared/widgets/app_loader.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter/material.dart';
import 'dart:ui';

/// ✅ Global Loader Widget (Reusable)
/// 
/// Usage Examples:
/// 
/// Login:
/// AppLoader(message: "Verifying user...")
/// 
/// Market Loading:
/// AppLoader(message: "Fetching market data...")
/// 
/// Pagination:
/// AppLoader(message: "Loading more stocks...")
class AppLoader extends StatelessWidget {

  /// ✅ Dynamic message passed from screen
  final String message;

  const AppLoader({
    super.key,
    required this.message, // ✅ Now mandatory (forces correct usage)
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        /// ✅ Blur background (block interaction)
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: Colors.black.withOpacity(0.25),
          ),
        ),

        /// ✅ Center content
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                /// ✅ Loader
                const CircularProgressIndicator(),

                const SizedBox(height: 16),

                /// ✅ Dynamic text
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
