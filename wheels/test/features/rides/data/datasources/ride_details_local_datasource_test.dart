import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheels/features/rides/data/datasources/ride_details_local_datasource.dart';
import 'package:wheels/features/rides/data/models/local_ride_details_cache_model.dart';
import 'package:wheels/shared/cache/memory_lru_cache.dart';
import 'package:wheels/shared/storage/app_hive.dart';

import '../../../../support/ride_test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const legacyPrefsKey = 'ride_details_cache_v1';
  late Directory hiveDirectory;
  late Box<String> rideDetailsBox;
  late MemoryLruCache<String, LocalRideDetailsCacheModel> memoryCache;
  late RideDetailsLocalDataSource dataSource;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('ride-details-test');
    Hive.init(hiveDirectory.path);
    rideDetailsBox = await Hive.openBox<String>(AppHiveBoxes.rideDetailsCache);
  });

  tearDown(() async {
    await rideDetailsBox.clear();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    memoryCache.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    memoryCache = MemoryLruCache<String, LocalRideDetailsCacheModel>(
      maxEntries: 4,
    );
    dataSource = RideDetailsLocalDataSource(
      memoryCache: memoryCache,
    );
  });

  group('RideDetailsLocalDataSource', () {
    test('returns null when there is no cache in memory, hive, or prefs', () async {
      final restored = await dataSource.loadRideDetails('ride-1');

      expect(restored, isNull);
    });

    test('saves to Hive and restores ride details', () async {
      final cache = buildRideDetailsCache(rideId: 'ride-1');

      await dataSource.saveRideDetails(cache);
      memoryCache.clear();

      final restored = await dataSource.loadRideDetails('ride-1');

      expect(restored, isNotNull);
      expect(restored!.rideId, 'ride-1');
      expect(restored.toEntity().driverName, 'Martin Driver');
      expect(rideDetailsBox.get('ride-1'), isNotNull);
    });

    test('returns the memory cache hit before checking Hive', () async {
      final cache = buildRideDetailsCache(rideId: 'ride-memory');
      memoryCache.put('ride-memory', cache);

      final restored = await dataSource.loadRideDetails('ride-memory');

      expect(restored, same(cache));
    });

    test('clears invalid Hive cache entries and returns null', () async {
      await rideDetailsBox.put('ride-1', '{"bad":');

      final restored = await dataSource.loadRideDetails('ride-1');

      expect(restored, isNull);
      expect(rideDetailsBox.get('ride-1'), isNull);
    });

    test('migrates legacy shared preferences cache into Hive storage', () async {
      final legacyCache = buildRideDetailsCache(rideId: 'ride-legacy');
      SharedPreferences.setMockInitialValues(<String, Object>{
        legacyPrefsKey: jsonEncode(legacyCache.toJson()),
      });

      final restored = await dataSource.loadRideDetails('ride-legacy');
      final prefs = await SharedPreferences.getInstance();

      expect(restored, isNotNull);
      expect(restored!.rideId, 'ride-legacy');
      expect(rideDetailsBox.get('ride-legacy'), isNotNull);
      expect(prefs.getString(legacyPrefsKey), isNull);
    });

    test('drops legacy cache if it belongs to a different ride', () async {
      final legacyCache = buildRideDetailsCache(rideId: 'ride-legacy');
      SharedPreferences.setMockInitialValues(<String, Object>{
        legacyPrefsKey: jsonEncode(legacyCache.toJson()),
      });

      final restored = await dataSource.loadRideDetails('other-ride');
      final prefs = await SharedPreferences.getInstance();

      expect(restored, isNull);
      expect(prefs.getString(legacyPrefsKey), isNull);
      expect(rideDetailsBox.values, isEmpty);
    });

    test('loadLatestRideDetails restores only the legacy shared preferences cache', () async {
      final legacyCache = buildRideDetailsCache(rideId: 'ride-latest');
      SharedPreferences.setMockInitialValues(<String, Object>{
        legacyPrefsKey: jsonEncode(legacyCache.toJson()),
      });

      final restored = await dataSource.loadLatestRideDetails();

      expect(restored, isNotNull);
      expect(restored!.rideId, 'ride-latest');
    });

    test('clearRideDetails removes both Hive and in-memory cache entries', () async {
      final cache = buildRideDetailsCache(rideId: 'ride-clear');
      await dataSource.saveRideDetails(cache);

      expect(memoryCache.containsKey('ride-clear'), isTrue);
      expect(rideDetailsBox.get('ride-clear'), isNotNull);

      await dataSource.clearRideDetails('ride-clear');

      expect(memoryCache.containsKey('ride-clear'), isFalse);
      expect(rideDetailsBox.get('ride-clear'), isNull);
    });
  });
}
