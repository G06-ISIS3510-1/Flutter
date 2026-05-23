import '../entities/reviews_entity.dart';

abstract class ReviewsRepository {
  const ReviewsRepository();

  Future<ReviewsEntity> getUserReviews({
    required String userId,
    required String fallbackFullName,
  });

  Future<ReviewsCacheSnapshot?> getCachedUserReviews(String userId);

  Future<void> clearCachedUserReviews(String userId);
}
