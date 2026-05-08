import '../../domain/entities/reviews_entity.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../datasources/reviews_local_datasource.dart';
import '../datasources/reviews_remote_datasource.dart';
import '../models/local_reviews_cache_model.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  const ReviewsRepositoryImpl({
    required ReviewsRemoteDataSource remoteDataSource,
    required ReviewsLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ReviewsRemoteDataSource _remoteDataSource;
  final ReviewsLocalDataSource _localDataSource;

  @override
  Future<ReviewsEntity> getUserReviews({
    required String userId,
    required String fallbackFullName,
  }) async {
    final reviews = await _remoteDataSource.fetchUserReviews(
      userId: userId,
      fallbackFullName: fallbackFullName,
    );
    await _localDataSource.saveUserReviews(
      LocalReviewsCacheModel.create(userId: userId, reviews: reviews),
    );
    return reviews;
  }

  @override
  Future<ReviewsCacheSnapshot?> getCachedUserReviews(String userId) async {
    final cache = await _localDataSource.loadUserReviews(userId);
    if (cache == null) {
      return null;
    }
    return ReviewsCacheSnapshot(
      reviews: cache.toEntity(),
      savedAt: cache.savedAt,
      isExpired: cache.isExpired(),
    );
  }

  @override
  Future<void> clearCachedUserReviews(String userId) {
    return _localDataSource.clearUserReviews(userId);
  }
}
