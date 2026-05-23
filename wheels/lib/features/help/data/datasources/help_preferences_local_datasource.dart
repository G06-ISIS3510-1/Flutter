import 'package:shared_preferences/shared_preferences.dart';

class HelpPreferencesLocalDataSource {
  HelpPreferencesLocalDataSource({
    Future<SharedPreferences> Function()? sharedPreferencesLoader,
  }) : _loader = sharedPreferencesLoader ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _loader;

  static const String _lastQueryKeyPrefix = 'help_last_query:';

  Future<String?> loadLastQuery(String userId) async {
    final prefs = await _loader();
    final value = prefs.getString(_buildKey(userId));
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> saveLastQuery({
    required String userId,
    required String query,
  }) async {
    final prefs = await _loader();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_buildKey(userId));
      return;
    }
    await prefs.setString(_buildKey(userId), trimmed);
  }

  Future<void> clearLastQuery(String userId) async {
    final prefs = await _loader();
    await prefs.remove(_buildKey(userId));
  }

  String _buildKey(String userId) {
    return '$_lastQueryKeyPrefix$userId';
  }
}
