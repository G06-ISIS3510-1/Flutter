import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreference { automatic, light, dark }

class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController() {
    WidgetsBinding.instance.addObserver(this);
    _evaluateTheme(notify: false);
    _loadPreference();
    _startThemeScheduler();
  }

  static const _preferenceKey = 'theme_preference';

  ThemePreference _preference = ThemePreference.automatic;
  ThemeMode _themeMode = ThemeMode.light;
  Timer? _themeTimer;

  ThemePreference get preference => _preference;
  ThemeMode get themeMode => _themeMode;
  bool get isAutomatic => _preference == ThemePreference.automatic;

  Future<void> setPreference(ThemePreference preference) async {
    _preference = preference;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, preference.name);
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

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPreference = prefs.getString(_preferenceKey);

    _preference = ThemePreference.values.firstWhere(
      (value) => value.name == rawPreference,
      orElse: () => ThemePreference.automatic,
    );
    _evaluateTheme(notify: true);
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
}

final themeControllerProvider = ChangeNotifierProvider<ThemeController>((ref) {
  return ThemeController();
});
