import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

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
  const WalletSummaryLocalDataSource();

  Future<LocalWalletSummaryCacheModel?> loadLatestWalletSummary() async {
    final box = Hive.box<String>(AppHiveBoxes.walletSummaryCache);
    final rawCache = box.get(AppHiveKeys.latestWalletSummary);
    if (rawCache == null || rawCache.trim().isEmpty) {
      return null;
    }

    try {
      return await compute(_decodeWalletSummaryCache, rawCache);
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
  }

  Future<void> clearLatestWalletSummary() async {
    final box = Hive.box<String>(AppHiveBoxes.walletSummaryCache);
    await box.delete(AppHiveKeys.latestWalletSummary);
  }
}
