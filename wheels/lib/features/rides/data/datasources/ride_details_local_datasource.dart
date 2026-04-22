import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_ride_details_cache_model.dart';

class RideDetailsLocalDataSource {
  static const String _cacheKey = 'ride_details_cache_v1';

  Future<LocalRideDetailsCacheModel?> loadLatestRideDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final rawCache = prefs.getString(_cacheKey);
    if (rawCache == null || rawCache.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawCache);
      if (decoded is! Map) {
        throw const FormatException('Stored ride details cache is invalid.');
      }

      return LocalRideDetailsCacheModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      await clearLatestRideDetails();
      return null;
    }
  }

  Future<void> saveLatestRideDetails(LocalRideDetailsCacheModel cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(cache.toJson()));
  }

  Future<void> clearLatestRideDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
