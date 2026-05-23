import 'package:shared_preferences/shared_preferences.dart';

class SavedDestinationsPreferencesLocalDataSource {
  const SavedDestinationsPreferencesLocalDataSource();

  Future<int?> loadLastQuickPick(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastQuickPickKey(userId));
  }

  Future<void> saveLastQuickPick({
    required String userId,
    required int localId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastQuickPickKey(userId), localId);
  }

  String _lastQuickPickKey(String userId) {
    return 'saved_destinations_last_pick:$userId';
  }
}
