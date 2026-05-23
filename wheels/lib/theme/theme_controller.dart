import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreference { automatic, light, dark }

class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController({
    ThemePreference initialPreference = ThemePreference.automatic,
    String? initialUserId,
  }) : _preference = initialPreference {
    _userId = _normalizeUserId(initialUserId);
    WidgetsBinding.instance.addObserver(this);
    _evaluateTheme(notify: false);
    _startThemeScheduler();
  }

  static const _guestPreferenceKey = 'theme_preference';
  static const _userPreferenceKeyPrefix = 'theme_preference_user_';

  //AQUI CARGAMOS LA PREFERENCIA DESDE LOCAL STORAGE
  static Future<ThemePreference> loadSavedPreference({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return _parsePreference(prefs.getString(_preferenceKeyForUser(userId)));
  }

  static ThemePreference _parsePreference(String? rawPreference) {
    return ThemePreference.values.firstWhere(
      (value) => value.name == rawPreference,
      orElse: () => ThemePreference.automatic,
    );
  }

  ThemePreference _preference;
  ThemeMode _themeMode = ThemeMode.light;
  Timer? _themeTimer;
  String? _userId;
  int _loadGeneration = 0;

  ThemePreference get preference => _preference;
  ThemeMode get themeMode => _themeMode;
  bool get isAutomatic => _preference == ThemePreference.automatic;

  
  //Y AQUÍ GUARDAMOS LA PREFERENCIA POR USUARIO
  Future<void> setPreference(ThemePreference preference) async {
    _loadGeneration++;
    _preference = preference;
    _evaluateTheme(notify: true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKeyForUser(_userId), preference.name);
  }

  Future<void> loadPreferenceForUser(String? userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (_userId == normalizedUserId) {
      return;
    }

    _userId = normalizedUserId;
    final generation = ++_loadGeneration;
    final prefs = await SharedPreferences.getInstance();
    if (generation != _loadGeneration) {
      return;
    }

    _preference = _parsePreference(
      prefs.getString(_preferenceKeyForUser(_userId)),
    );
    _evaluateTheme(notify: true);
  }

  void refreshTheme() {
    _evaluateTheme(notify: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluateTheme(notify: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeTimer?.cancel();
    super.dispose();
  }

  void _startThemeScheduler() {
    _themeTimer?.cancel();
    _themeTimer = Timer.periodic(
      const Duration(minutes: 20),
      (_) => _evaluateTheme(notify: true),
    );
  }

  void _evaluateTheme({required bool notify}) {
    final nextMode = switch (_preference) {
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
      ThemePreference.automatic =>
        _isDarkWindowNow() ? ThemeMode.dark : ThemeMode.light,
    };

    if (_themeMode != nextMode) {
      _themeMode = nextMode;
      notifyListeners();
      return;
    }

    if (notify) {
      notifyListeners();
    }
  }

  bool _isDarkWindowNow() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 18 || hour < 6;
  }

  static String? _normalizeUserId(String? userId) {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return null;
    }
    return normalizedUserId;
  }

  static String _preferenceKeyForUser(String? userId) {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) {
      return _guestPreferenceKey;
    }
    return '$_userPreferenceKeyPrefix$normalizedUserId';
  }
}

final themeControllerProvider = ChangeNotifierProvider<ThemeController>((ref) {
  return ThemeController();
});
