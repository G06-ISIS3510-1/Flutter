import 'package:flutter/material.dart';

@immutable
class AppThemePalette extends ThemeExtension<AppThemePalette> {
  const AppThemePalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.card,
    required this.cardSecondary,
    required this.border,
    required this.input,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.primaryForeground,
    required this.primaryLight,
    required this.accent,
    required this.accentForeground,
    required this.accentSoft,
    required this.secondary,
    required this.secondarySoft,
    required this.warning,
    required this.error,
    required this.drawerBackground,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color card;
  final Color cardSecondary;
  final Color border;
  final Color input;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color primaryForeground;
  final Color primaryLight;
  final Color accent;
  final Color accentForeground;
  final Color accentSoft;
  final Color secondary;
  final Color secondarySoft;
  final Color warning;
  final Color error;
  final Color drawerBackground;
  final Color shadow;

  static const light = AppThemePalette(
    background: Color(0xFFF4F7FB),
    surface: Color(0xFFF9FBFE),
    surfaceMuted: Color(0xFFEAF1F8),
    card: Color(0xFFFDFEFF),
    cardSecondary: Color(0xFFF2F6FB),
    border: Color(0xFFD9E3EF),
    input: Color(0xFFF5F8FC),
    textPrimary: Color(0xFF1A1F36),
    textSecondary: Color(0xFF64748B),
    primary: Color(0xFF1A3A5C),
    primaryForeground: Color(0xFFFFFFFF),
    primaryLight: Color(0xFF2D5280),
    accent: Color(0xFF00D9A3),
    accentForeground: Color(0xFF1A1F36),
    accentSoft: Color(0xFFE8FBF4),
    secondary: Color(0xFF5B89C8),
    secondarySoft: Color(0xFFE8F0F9),
    warning: Color(0xFFFFA726),
    error: Color(0xFFFF5252),
    drawerBackground: Color(0xFFF8FBFF),
    shadow: Color(0x1A1A3A5C),
  );

  static const dark = AppThemePalette(
    background: Color(0xFF11161E),
    surface: Color(0xFF161C25),
    surfaceMuted: Color(0xFF1C2430),
    card: Color(0xFF1A222D),
    cardSecondary: Color(0xFF202A37),
    border: Color(0xFF2D3A4D),
    input: Color(0xFF202A37),
    textPrimary: Color(0xFFF3F7FC),
    textSecondary: Color(0xFFA1B0C5),
    primary: Color(0xFF274A6F),
    primaryForeground: Color(0xFFFFFFFF),
    primaryLight: Color(0xFF35628F),
    accent: Color(0xFF4ED8A5),
    accentForeground: Color(0xFF0E1A17),
    accentSoft: Color(0xFF17322A),
    secondary: Color(0xFF7EA6DD),
    secondarySoft: Color(0xFF203246),
    warning: Color(0xFFFFB74D),
    error: Color(0xFFFF7B7B),
    drawerBackground: Color(0xFF141B24),
    shadow: Color(0x66000000),
  );

  @override
  AppThemePalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? card,
    Color? cardSecondary,
    Color? border,
    Color? input,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? primaryForeground,
    Color? primaryLight,
    Color? accent,
    Color? accentForeground,
    Color? accentSoft,
    Color? secondary,
    Color? secondarySoft,
    Color? warning,
    Color? error,
    Color? drawerBackground,
    Color? shadow,
  }) {
    return AppThemePalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      card: card ?? this.card,
      cardSecondary: cardSecondary ?? this.cardSecondary,
      border: border ?? this.border,
      input: input ?? this.input,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      accentSoft: accentSoft ?? this.accentSoft,
      secondary: secondary ?? this.secondary,
      secondarySoft: secondarySoft ?? this.secondarySoft,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      drawerBackground: drawerBackground ?? this.drawerBackground,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppThemePalette lerp(ThemeExtension<AppThemePalette>? other, double t) {
    if (other is! AppThemePalette) {
      return this;
    }

    return AppThemePalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardSecondary: Color.lerp(cardSecondary, other.cardSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(
        primaryForeground,
        other.primaryForeground,
        t,
      )!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(
        accentForeground,
        other.accentForeground,
        t,
      )!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondarySoft: Color.lerp(secondarySoft, other.secondarySoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      drawerBackground: Color.lerp(
        drawerBackground,
        other.drawerBackground,
        t,
      )!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppThemePaletteContext on BuildContext {
  AppThemePalette get palette =>
      Theme.of(this).extension<AppThemePalette>() ?? AppThemePalette.light;
}
