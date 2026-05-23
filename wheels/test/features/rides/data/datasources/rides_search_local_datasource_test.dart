import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheels/features/rides/data/datasources/rides_search_local_datasource.dart';

import '../../../../support/ride_test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cacheKey = 'rides_search_cache_v1';
  late RidesSearchLocalDataSource dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    dataSource = RidesSearchLocalDataSource();
  });

  group('RidesSearchLocalDataSource', () {
    test('returns null when there is no cached search', () async {
      final result = await dataSource.loadLatestSearch();

      expect(result, isNull);
    });

    test('saves and restores the latest search cache', () async {
      final cache = buildSearchCache();

      await dataSource.saveLatestSearch(cache);
      final restored = await dataSource.loadLatestSearch();

      expect(restored, isNotNull);
      expect(restored!.filters.originQuery, cache.filters.originQuery);
      expect(restored.filters.destinationQuery, cache.filters.destinationQuery);
      expect(restored.filters.sort, cache.filters.sort);
      expect(restored.results.map((ride) => ride.id), <String>['ride-1', 'ride-2']);
    });

    test('returns null and clears storage when cached payload is invalid', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        cacheKey: '{"version":1,"savedAt":"oops"',
      });

      final restored = await dataSource.loadLatestSearch();
      final prefs = await SharedPreferences.getInstance();

      expect(restored, isNull);
      expect(prefs.getString(cacheKey), isNull);
    });

    test('clearLatestSearch removes a previously saved cache', () async {
      final cache = buildSearchCache();
      await dataSource.saveLatestSearch(cache);

      await dataSource.clearLatestSearch();
      final restored = await dataSource.loadLatestSearch();

      expect(restored, isNull);
    });

    test('returns null for blank stored strings', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{cacheKey: '   '});

      final restored = await dataSource.loadLatestSearch();

      expect(restored, isNull);
    });
  });
}
