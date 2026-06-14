// File: lib/config/theme/app_theme.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// ✅ Global Theme Configuration
/// 
/// 📌 Purpose:
/// - Central UI styling
/// - Consistent look across app
/// - Fix button disabled / faded issue
/// 
/// ✅ Covers:
/// - Colors
/// - Buttons
/// - Inputs
/// - Text
class AppTheme {

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    /// ✅ Global Colors
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),

    /// ✅ AppBar Theme (Clean fintech style)
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.textPrimary,
      centerTitle: true,
    ),

    /// ✅ Input Fields (GLOBAL)
    /// Consistent styling for all TextFields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.padding,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: BorderSide.none,
      ),
    ),

    /// ✅ BUTTON THEME (IMPORTANT FIX ✅)
    /// Fixes faded / disabled look issue
    elevatedButtonTheme: ElevatedButtonThemeData(

      style: ElevatedButton.styleFrom(

        /// ✅ Button background
        backgroundColor: AppColors.primary,

        /// ✅ TEXT COLOR FIX (VERY IMPORTANT)
        /// Without this → text appears grey (your issue)
        foregroundColor: Colors.white,

        /// ✅ Disabled state styling
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,

        /// ✅ Size consistency
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),

        /// ✅ Shape
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),

        elevation: 2,

        /// ✅ Text styling
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    /// ✅ Text Theme (basic)
    /// Can be extended later for heading, subtitle, etc.
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    ),
  );
}
