import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wheels/features/reviews/data/datasources/reviews_local_datasource.dart';
import 'package:wheels/features/reviews/data/models/local_reviews_cache_model.dart';
import 'package:wheels/features/reviews/data/models/reviews_model.dart';
import 'package:wheels/shared/cache/memory_lru_cache.dart';
import 'package:wheels/shared/storage/app_hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late Box<String> reviewsBox;
  late MemoryLruCache<String, LocalReviewsCacheModel> memoryCache;
  late ReviewsLocalDataSource dataSource;

  LocalReviewsCacheModel buildCache({
    String userId = 'user-1',
    String fullName = 'Maria Gonzalez',
  }) {
    return LocalReviewsCacheModel.create(
      userId: userId,
      reviews: ReviewsModel.sampleForUser(
        userId: userId,
        fallbackFullName: fullName,
      ),
    );
  }

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('reviews-cache-test');
    Hive.init(hiveDirectory.path);
    reviewsBox = await Hive.openBox<String>(AppHiveBoxes.userReviewsCache);
  });

  setUp(() {
    memoryCache = MemoryLruCache<String, LocalReviewsCacheModel>(maxEntries: 4);
    dataSource = ReviewsLocalDataSource(memoryCache: memoryCache);
  });

  tearDown(() async {
    await reviewsBox.clear();
    memoryCache.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  group('ReviewsLocalDataSource', () {
    test('returns null when there is no cache', () async {
      final restored = await dataSource.loadUserReviews('user-1');

      expect(restored, isNull);
    });

    test('saves to Hive and restores user reviews', () async {
      final cache = buildCache(userId: 'user-1');

      await dataSource.saveUserReviews(cache);
      memoryCache.clear();

      final restored = await dataSource.loadUserReviews('user-1');

      expect(restored, isNotNull);
      expect(restored!.userId, 'user-1');
      expect(restored.toEntity().user.fullName, 'Maria Gonzalez');
      expect(reviewsBox.get('user-1'), isNotNull);
    });

    test('returns the memory cache hit before checking Hive', () async {
      final cache = buildCache(userId: 'user-memory', fullName: 'Memory User');
      memoryCache.put('user-memory', cache);

      final restored = await dataSource.loadUserReviews('user-memory');

      expect(restored, same(cache));
    });

    test('clears invalid Hive cache entries and returns null', () async {
      await reviewsBox.put('user-1', '{"bad":');

      final restored = await dataSource.loadUserReviews('user-1');

      expect(restored, isNull);
      expect(reviewsBox.get('user-1'), isNull);
    });

    test(
      'clearUserReviews removes both Hive and memory cache entries',
      () async {
        final cache = buildCache(userId: 'user-clear');
        await dataSource.saveUserReviews(cache);

        expect(memoryCache.containsKey('user-clear'), isTrue);
        expect(reviewsBox.get('user-clear'), isNotNull);

        await dataSource.clearUserReviews('user-clear');

        expect(memoryCache.containsKey('user-clear'), isFalse);
        expect(reviewsBox.get('user-clear'), isNull);
      },
    );
  });
}
