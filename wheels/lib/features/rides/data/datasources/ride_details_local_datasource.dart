import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/cache/memory_lru_cache.dart';
import '../../../../shared/storage/app_hive.dart';
import '../models/local_ride_details_cache_model.dart';

class RideDetailsLocalDataSource {
  RideDetailsLocalDataSource({required MemoryLruCache<String, LocalRideDetailsCacheModel> memoryCache})
    : _memoryCache = memoryCache;

  static const String _cacheKey = 'ride_details_cache_v1';
  final MemoryLruCache<String, LocalRideDetailsCacheModel> _memoryCache;

  Future<LocalRideDetailsCacheModel?> loadRideDetails(String rideId) async {
    final memoryHit = _memoryCache.get(rideId);
    if (memoryHit != null) {
      return memoryHit;
    }

    final box = Hive.box<String>(AppHiveBoxes.rideDetailsCache);
    final rawCache = box.get(rideId);
    if (rawCache != null && rawCache.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCache);
        if (decoded is! Map) {
          throw const FormatException('Stored ride details cache is invalid.');
        }

        final cache = LocalRideDetailsCacheModel.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        _memoryCache.put(rideId, cache);
        return cache;
      } catch (_) {
        await clearRideDetails(rideId);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyRawCache = prefs.getString(_cacheKey);
    if (legacyRawCache == null || legacyRawCache.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(legacyRawCache);
      if (decoded is! Map) {
        throw const FormatException('Stored ride details cache is invalid.');
      }

      final cache = LocalRideDetailsCacheModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (cache.rideId != rideId) {
        await prefs.remove(_cacheKey);
        return null;
      }

      await saveRideDetails(cache);
      await prefs.remove(_cacheKey);
      return cache;
    } catch (_) {
      await prefs.remove(_cacheKey);
      return null;
    }
  }

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
      await prefs.remove(_cacheKey);
      return null;
    }
  }

  Future<void> saveRideDetails(LocalRideDetailsCacheModel cache) async {
    final encoded = jsonEncode(cache.toJson());
    final box = Hive.box<String>(AppHiveBoxes.rideDetailsCache);
    await box.put(cache.rideId, encoded);
    _memoryCache.put(cache.rideId, cache);
  }

  Future<void> clearRideDetails(String rideId) async {
    final box = Hive.box<String>(AppHiveBoxes.rideDetailsCache);
    await box.delete(rideId);
    _memoryCache.remove(rideId);
  }
}
