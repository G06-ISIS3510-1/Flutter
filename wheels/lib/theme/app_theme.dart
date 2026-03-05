import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.cardForeground,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.foreground,
      ),
    );

    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.input,
        hintStyle: const TextStyle(color: AppColors.mutedForeground),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.accent.withValues(alpha: 0.2),
        backgroundColor: AppColors.card,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        shadowColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerColor: AppShadows.divider,
    );
  }
}
