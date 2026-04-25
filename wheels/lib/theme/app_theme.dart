import 'package:flutter/material.dart';

import 'app_radius.dart';
import 'app_theme_palette.dart';

class AppTheme {
  static ThemeData get light =>
      _buildTheme(brightness: Brightness.light, palette: AppThemePalette.light);

  static ThemeData get dark =>
      _buildTheme(brightness: Brightness.dark, palette: AppThemePalette.dark);

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppThemePalette palette,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.primaryForeground,
      secondary: palette.secondary,
      onSecondary: palette.primaryForeground,
      error: palette.error,
      onError: palette.primaryForeground,
      surface: palette.card,
      onSurface: palette.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.drawerBackground,
      cardColor: palette.card,
      dividerColor: palette.border,
      shadowColor: palette.shadow,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: palette.card,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.input,
        hintStyle: TextStyle(color: palette.textSecondary),
        labelStyle: TextStyle(color: palette.textSecondary),
        prefixIconColor: palette.textSecondary,
        suffixIconColor: palette.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.error, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.accentForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          foregroundColor: palette.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: EdgeInsets.zero,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: palette.drawerBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.primary,
        contentTextStyle: TextStyle(color: palette.primaryForeground),
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.card,
        indicatorColor: palette.accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? palette.textPrimary
                : palette.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
    );
  }
}
