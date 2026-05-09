import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../shared/cache/memory_lru_cache.dart';
import '../../../../shared/storage/app_hive.dart';
import '../models/local_trust_cache_model.dart';

LocalTrustCacheModel _decodeTrustCache(String rawCache) {
  final decoded = jsonDecode(rawCache);
  if (decoded is! Map) {
    throw const FormatException('Stored trust cache is invalid.');
  }
  return LocalTrustCacheModel.fromJson(Map<String, dynamic>.from(decoded));
}

String _encodeTrustCache(LocalTrustCacheModel cache) {
  return jsonEncode(cache.toJson());
}

class TrustLocalDataSource {
  TrustLocalDataSource({
    required MemoryLruCache<String, LocalTrustCacheModel> memoryCache,
  }) : _memoryCache = memoryCache;

  final MemoryLruCache<String, LocalTrustCacheModel> _memoryCache;

  Future<LocalTrustCacheModel?> loadTrustScore(String userId) async {
    final memoryHit = _memoryCache.get(userId);
    if (memoryHit != null && memoryHit.matchesUser(userId)) {
      return memoryHit;
    }

    final box = Hive.box<String>(AppHiveBoxes.trustScoreCache);
    final rawCache = box.get(userId);
    if (rawCache == null || rawCache.trim().isEmpty) {
      return null;
    }

    try {
      final cache = await compute(_decodeTrustCache, rawCache);
      if (!cache.matchesUser(userId)) {
        await clearTrustScore(userId);
        return null;
      }

      _memoryCache.put(userId, cache);
      return cache;
    } catch (_) {
      await clearTrustScore(userId);
      return null;
    }
  }

  Future<void> saveTrustScore(LocalTrustCacheModel cache) async {
    final encoded = await compute(_encodeTrustCache, cache);
    final box = Hive.box<String>(AppHiveBoxes.trustScoreCache);
    await box.put(cache.userId, encoded);
    _memoryCache.put(cache.userId, cache);
  }

  Future<void> clearTrustScore(String userId) async {
    final box = Hive.box<String>(AppHiveBoxes.trustScoreCache);
    await box.delete(userId);
    _memoryCache.remove(userId);
  }
}
