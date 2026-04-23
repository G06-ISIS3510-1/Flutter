import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/cache/memory_lru_cache.dart';
import '../../data/datasources/dashboard_local_datasource.dart';
import '../../data/models/dashboard_model.dart';

final dashboardSummaryProvider = Provider<String>((ref) => 'Dashboard overview');
final dashboardCardCountProvider = StateProvider<int>((ref) => 3);
final dashboardMemoryCacheProvider =
    Provider<MemoryLruCache<String, DashboardModel>>((ref) {
      return MemoryLruCache<String, DashboardModel>(maxEntries: 4);
    });
final dashboardLocalDataSourceProvider = Provider<DashboardLocalDataSource>((ref) {
  return DashboardLocalDataSource(
    memoryCache: ref.watch(dashboardMemoryCacheProvider),
  );
});
