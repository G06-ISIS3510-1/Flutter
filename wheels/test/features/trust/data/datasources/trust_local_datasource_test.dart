import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wheels/features/trust/data/datasources/trust_local_datasource.dart';
import 'package:wheels/features/trust/data/models/local_trust_cache_model.dart';
import 'package:wheels/features/trust/data/models/trust_model.dart';
import 'package:wheels/shared/cache/memory_lru_cache.dart';
import 'package:wheels/shared/storage/app_hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late Box<String> trustBox;
  late MemoryLruCache<String, LocalTrustCacheModel> memoryCache;
  late TrustLocalDataSource dataSource;

  TrustModel buildTrust({String userId = 'user-1', int score = 88}) {
    return TrustModel(
      userId: userId,
      role: 'driver',
      accountCreatedAt: DateTime.utc(2026, 1, 1),
      totalRides: 6,
      completedRides: 5,
      cancelledRides: 1,
      activeRides: 0,
      totalPayments: 5,
      approvedPayments: 4,
      pendingPayments: 1,
      failedPayments: 0,
      score: score,
      rewardPoints: 56,
    );
  }

  LocalTrustCacheModel buildCache({String userId = 'user-1', int score = 88}) {
    return LocalTrustCacheModel.create(
      userId: userId,
      trust: buildTrust(userId: userId, score: score),
    );
  }

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('trust-cache-test');
    Hive.init(hiveDirectory.path);
    trustBox = await Hive.openBox<String>(AppHiveBoxes.trustScoreCache);
  });

  setUp(() {
    memoryCache = MemoryLruCache<String, LocalTrustCacheModel>(maxEntries: 4);
    dataSource = TrustLocalDataSource(memoryCache: memoryCache);
  });

  tearDown(() async {
    await trustBox.clear();
    memoryCache.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  group('TrustLocalDataSource', () {
    test('returns null when there is no cache', () async {
      final restored = await dataSource.loadTrustScore('user-1');

      expect(restored, isNull);
    });

    test('saves to Hive and restores a trust score', () async {
      final cache = buildCache(userId: 'user-1', score: 91);

      await dataSource.saveTrustScore(cache);
      memoryCache.clear();

      final restored = await dataSource.loadTrustScore('user-1');

      expect(restored, isNotNull);
      expect(restored!.userId, 'user-1');
      expect(restored.toEntity().score, 91);
      expect(trustBox.get('user-1'), isNotNull);
    });

    test('returns the memory cache hit before checking Hive', () async {
      final cache = buildCache(userId: 'user-memory', score: 77);
      memoryCache.put('user-memory', cache);

      final restored = await dataSource.loadTrustScore('user-memory');

      expect(restored, same(cache));
    });

    test('clears invalid Hive cache entries and returns null', () async {
      await trustBox.put('user-1', '{"bad":');

      final restored = await dataSource.loadTrustScore('user-1');

      expect(restored, isNull);
      expect(trustBox.get('user-1'), isNull);
    });

    test(
      'clearTrustScore removes both Hive and memory cache entries',
      () async {
        final cache = buildCache(userId: 'user-clear');
        await dataSource.saveTrustScore(cache);

        expect(memoryCache.containsKey('user-clear'), isTrue);
        expect(trustBox.get('user-clear'), isNotNull);

        await dataSource.clearTrustScore('user-clear');

        expect(memoryCache.containsKey('user-clear'), isFalse);
        expect(trustBox.get('user-clear'), isNull);
      },
    );
  });
}
