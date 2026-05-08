import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/features/reviews/data/models/local_reviews_cache_model.dart';
import 'package:wheels/features/reviews/data/models/reviews_model.dart';
import 'package:wheels/features/reviews/domain/entities/reviews_entity.dart';

void main() {
  group('LocalReviewsCacheModel', () {
    test('round-trips through json and restores reviews', () {
      final cache = LocalReviewsCacheModel.create(
        userId: 'user-1',
        reviews: ReviewsModel.sampleForUser(
          userId: 'user-1',
          fallbackFullName: 'Maria Gonzalez',
        ),
      );

      final restored = LocalReviewsCacheModel.fromJson(cache.toJson());

      expect(restored.version, LocalReviewsCacheModel.currentVersion);
      expect(restored.userId, 'user-1');
      expect(restored.toEntity().user.fullName, 'Maria Gonzalez');
      expect(restored.toEntity().reviews, hasLength(5));
      expect(
        restored.toEntity().reviews.first.roleTag,
        ReviewRoleTag.passenger,
      );
    });

    test('matchesUser only returns true for the cached user id', () {
      final cache = LocalReviewsCacheModel.create(
        userId: 'user-42',
        reviews: ReviewsModel.sampleForUser(
          userId: 'user-42',
          fallbackFullName: 'Ana Torres',
        ),
      );

      expect(cache.matchesUser('user-42'), isTrue);
      expect(cache.matchesUser('other-user'), isFalse);
    });

    test('isExpired returns true for old cache entries', () {
      final cache = LocalReviewsCacheModel(
        version: LocalReviewsCacheModel.currentVersion,
        userId: 'user-old',
        savedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        reviews: ReviewsModel.sampleForUser(
          userId: 'user-old',
          fallbackFullName: 'Old User',
        ),
      );

      expect(cache.isExpired(), isTrue);
    });

    test('isExpired returns false for recent cache entries', () {
      final cache = LocalReviewsCacheModel(
        version: LocalReviewsCacheModel.currentVersion,
        userId: 'user-fresh',
        savedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
        reviews: ReviewsModel.sampleForUser(
          userId: 'user-fresh',
          fallbackFullName: 'Fresh User',
        ),
      );

      expect(cache.isExpired(), isFalse);
    });
  });
}
