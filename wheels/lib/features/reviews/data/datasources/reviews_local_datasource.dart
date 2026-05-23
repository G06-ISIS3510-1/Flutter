import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../shared/cache/memory_lru_cache.dart';
import '../../../../shared/storage/app_hive.dart';
import '../models/local_reviews_cache_model.dart';

LocalReviewsCacheModel _decodeReviewsCache(String rawCache) {
  final decoded = jsonDecode(rawCache);
  if (decoded is! Map) {
    throw const FormatException('Stored reviews cache is invalid.');
  }
  return LocalReviewsCacheModel.fromJson(Map<String, dynamic>.from(decoded));
}

String _encodeReviewsCache(LocalReviewsCacheModel cache) {
  return jsonEncode(cache.toJson());
}

class ReviewsLocalDataSource {
  ReviewsLocalDataSource({
    required MemoryLruCache<String, LocalReviewsCacheModel> memoryCache,
  }) : _memoryCache = memoryCache;


  //AQUI PEDIMOS QUE SE CONSULTE LRU
  final MemoryLruCache<String, LocalReviewsCacheModel> _memoryCache;

  Future<LocalReviewsCacheModel?> loadUserReviews(String userId) async {
    final memoryHit = _memoryCache.get(userId);
    if (memoryHit != null && memoryHit.matchesUser(userId)) {
      return memoryHit;
    }

    // SI NO VER EN HIVE
    final box = Hive.box<String>(AppHiveBoxes.userReviewsCache);
    final rawCache = box.get(userId);
    if (rawCache == null || rawCache.trim().isEmpty) {
      return null;
    }

    try {
      // Uso de isolate
      final cache = await compute(_decodeReviewsCache, rawCache);
      if (!cache.matchesUser(userId)) {
        await clearUserReviews(userId);
        return null;
      }

      //GUARDAR EN CACHE
      _memoryCache.put(userId, cache);
      return cache;
    } catch (_) {
      await clearUserReviews(userId);
      return null;
    }
  }

  Future<void> saveUserReviews(LocalReviewsCacheModel cache) async {
    // Uso de Isolate
    final encoded = await compute(_encodeReviewsCache, cache);
    final box = Hive.box<String>(AppHiveBoxes.userReviewsCache);
    await box.put(cache.userId, encoded);
    _memoryCache.put(cache.userId, cache);
  }

  Future<void> clearUserReviews(String userId) async {
    final box = Hive.box<String>(AppHiveBoxes.userReviewsCache);
    await box.delete(userId);
    _memoryCache.remove(userId);
  }
}
