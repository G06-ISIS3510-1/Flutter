import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_ride_search_cache_model.dart';

LocalRideSearchCacheModel? _decodeSearchCache(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('Stored rides search cache is invalid.');
  }
  return LocalRideSearchCacheModel.fromJson(Map<String, dynamic>.from(decoded));
}

String _encodeSearchCache(LocalRideSearchCacheModel cache) {
  return jsonEncode(cache.toJson());
}

class RidesSearchLocalDataSource {
  static const String _cacheKey = 'rides_search_cache_v1';

  Future<LocalRideSearchCacheModel?> loadLatestSearch() async {
    final prefs = await SharedPreferences.getInstance();
    final rawCache = prefs.getString(_cacheKey);
    if (rawCache == null || rawCache.trim().isEmpty) {
      return null;
    }

    try {
      return await compute(_decodeSearchCache, rawCache);
    } catch (_) {
      await clearLatestSearch();
      return null;
    }
  }

  Future<void> saveLatestSearch(LocalRideSearchCacheModel cache) async {
    final encoded = await compute(_encodeSearchCache, cache);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, encoded);
  }

  Future<void> clearLatestSearch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
