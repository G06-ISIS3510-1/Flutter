import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/cache/memory_lru_cache.dart';
import '../../../../shared/storage/app_hive.dart';
import '../models/dashboard_model.dart';

class DashboardLocalDataSource {
  DashboardLocalDataSource({required MemoryLruCache<String, DashboardModel> memoryCache})
    : _memoryCache = memoryCache;

  static const String _cacheKey = 'dashboard_cache_v1';
  final MemoryLruCache<String, DashboardModel> _memoryCache;

  Future<DashboardModel?> loadLatestDashboard() async {
    final memoryHit = _memoryCache.get(AppHiveKeys.latestDashboard);
    if (memoryHit != null) {
      return memoryHit;
    }

    final box = Hive.box<String>(AppHiveBoxes.dashboardCache);
    final hiveRawCache = box.get(AppHiveKeys.latestDashboard);
    if (hiveRawCache != null && hiveRawCache.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(hiveRawCache);
        if (decoded is! Map) {
          throw const FormatException('Stored dashboard cache is invalid.');
        }

        final cache = DashboardModel.fromJson(Map<String, dynamic>.from(decoded));
        _memoryCache.put(AppHiveKeys.latestDashboard, cache);
        return cache;
      } catch (_) {
        await clearLatestDashboard();
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final rawCache = prefs.getString(_cacheKey);
    if (rawCache == null || rawCache.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawCache);
      if (decoded is! Map) {
        throw const FormatException('Stored dashboard cache is invalid.');
      }

      final cache = DashboardModel.fromJson(Map<String, dynamic>.from(decoded));
      await saveLatestDashboard(cache);
      await prefs.remove(_cacheKey);
      return cache;
    } catch (_) {
      await prefs.remove(_cacheKey);
      return null;
    }
  }

  Future<void> saveLatestDashboard(DashboardModel dashboard) async {
    final encoded = jsonEncode(dashboard.toJson());
    final box = Hive.box<String>(AppHiveBoxes.dashboardCache);
    await box.put(AppHiveKeys.latestDashboard, encoded);
    _memoryCache.put(AppHiveKeys.latestDashboard, dashboard);
  }

  Future<void> clearLatestDashboard() async {
    final box = Hive.box<String>(AppHiveBoxes.dashboardCache);
    await box.delete(AppHiveKeys.latestDashboard);
    _memoryCache.remove(AppHiveKeys.latestDashboard);
  }
}
