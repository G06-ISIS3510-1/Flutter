import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../shared/cache/memory_lru_cache.dart';
import '../../../../shared/storage/app_hive.dart';
import '../models/local_wallet_summary_cache_model.dart';

LocalWalletSummaryCacheModel _decodeWalletSummaryCache(String rawCache) {
  final decoded = jsonDecode(rawCache);
  if (decoded is! Map) {
    throw const FormatException('Stored wallet cache is invalid.');
  }

  return LocalWalletSummaryCacheModel.fromJson(
    Map<String, dynamic>.from(decoded),
  );
}

String _encodeWalletSummaryCache(LocalWalletSummaryCacheModel cache) {
  return jsonEncode(cache.toJson());
}

class WalletSummaryLocalDataSource {
  WalletSummaryLocalDataSource({
    required MemoryLruCache<String, LocalWalletSummaryCacheModel> memoryCache,
  }) : _memoryCache = memoryCache;

  final MemoryLruCache<String, LocalWalletSummaryCacheModel> _memoryCache;

  Future<LocalWalletSummaryCacheModel?> loadLatestWalletSummary() async {
    final memoryHit = _memoryCache.get(AppHiveKeys.latestWalletSummary);
    if (memoryHit != null) {
      return memoryHit;
    }

    final box = Hive.box<String>(AppHiveBoxes.walletSummaryCache);
    final rawCache = box.get(AppHiveKeys.latestWalletSummary);
    if (rawCache == null || rawCache.trim().isEmpty) {
      return null;
    }

    try {
      final cache = await compute(_decodeWalletSummaryCache, rawCache);
      _memoryCache.put(AppHiveKeys.latestWalletSummary, cache);
      return cache;
    } catch (_) {
      await clearLatestWalletSummary();
      return null;
    }
  }

  Future<void> saveLatestWalletSummary(
    LocalWalletSummaryCacheModel cache,
  ) async {
    final encoded = await compute(_encodeWalletSummaryCache, cache);
    final box = Hive.box<String>(AppHiveBoxes.walletSummaryCache);
    await box.put(AppHiveKeys.latestWalletSummary, encoded);
    _memoryCache.put(AppHiveKeys.latestWalletSummary, cache);
  }

  Future<void> clearLatestWalletSummary() async {
    final box = Hive.box<String>(AppHiveBoxes.walletSummaryCache);
    await box.delete(AppHiveKeys.latestWalletSummary);
    _memoryCache.remove(AppHiveKeys.latestWalletSummary);
  }
}
