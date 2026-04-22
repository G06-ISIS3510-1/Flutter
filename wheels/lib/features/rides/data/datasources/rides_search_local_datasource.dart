import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_ride_search_cache_model.dart';

class RidesSearchLocalDataSource {
  static const String _cacheKey = 'rides_search_cache_v1';

  Future<LocalRideSearchCacheModel?> loadLatestSearch() async {
    final prefs = await SharedPreferences.getInstance();
    final rawCache = prefs.getString(_cacheKey);
    if (rawCache == null || rawCache.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawCache);
      if (decoded is! Map) {
        throw const FormatException('Stored rides search cache is invalid.');
      }

      return LocalRideSearchCacheModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      await clearLatestSearch();
      return null;
    }
  }

  Future<void> saveLatestSearch(LocalRideSearchCacheModel cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(cache.toJson()));
  }

  Future<void> clearLatestSearch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
