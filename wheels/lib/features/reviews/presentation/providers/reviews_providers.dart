import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/cache/memory_lru_cache.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/reviews_local_datasource.dart';
import '../../data/datasources/reviews_remote_datasource.dart';
import '../../data/models/local_reviews_cache_model.dart';
import '../../data/repositories/reviews_repository_impl.dart';
import '../../domain/entities/reviews_entity.dart';
import '../../domain/repositories/reviews_repository.dart';

export '../../domain/entities/reviews_entity.dart' show ReviewRoleTag;

enum ReviewFilter { all, asDriver, asPassenger, recent }

class ReviewedUserData {
  const ReviewedUserData({
    required this.fullName,
    required this.initials,
    required this.badgeLabel,
    required this.memberSince,
    required this.averageRating,
    required this.totalReviews,
    required this.supportingText,
  });

  factory ReviewedUserData.fromEntity(ReviewedUserEntity entity) {
    return ReviewedUserData(
      fullName: entity.fullName,
      initials: entity.initials,
      badgeLabel: entity.badgeLabel,
      memberSince: entity.memberSince,
      averageRating: entity.averageRating,
      totalReviews: entity.totalReviews,
      supportingText: entity.supportingText,
    );
  }

  final String fullName;
  final String initials;
  final String badgeLabel;
  final String memberSince;
  final double averageRating;
  final int totalReviews;
  final String supportingText;
}

class ReviewItemData {
  const ReviewItemData({
    required this.reviewerName,
    required this.reviewerInitials,
    required this.rating,
    required this.roleTag,
    required this.dateLabel,
    required this.reviewText,
  });

  factory ReviewItemData.fromEntity(ReviewItemEntity entity) {
    return ReviewItemData(
      reviewerName: entity.reviewerName,
      reviewerInitials: entity.reviewerInitials,
      rating: entity.rating,
      roleTag: entity.roleTag,
      dateLabel: entity.dateLabel,
      reviewText: entity.reviewText,
    );
  }

  final String reviewerName;
  final String reviewerInitials;
  final int rating;
  final ReviewRoleTag roleTag;
  final String dateLabel;
  final String reviewText;
}

class ReviewBreakdownItemData {
  const ReviewBreakdownItemData({required this.stars, required this.count});

  factory ReviewBreakdownItemData.fromEntity(ReviewBreakdownItemEntity entity) {
    return ReviewBreakdownItemData(stars: entity.stars, count: entity.count);
  }

  final int stars;
  final int count;
}

class ReviewsViewData {
  const ReviewsViewData({
    required this.user,
    required this.reviews,
    required this.breakdown,
  });

  factory ReviewsViewData.fromEntity(ReviewsEntity entity) {
    return ReviewsViewData(
      user: ReviewedUserData.fromEntity(entity.user),
      reviews: entity.reviews.map(ReviewItemData.fromEntity).toList(),
      breakdown: entity.breakdown
          .map(ReviewBreakdownItemData.fromEntity)
          .toList(),
    );
  }

  final ReviewedUserData user;
  final List<ReviewItemData> reviews;
  final List<ReviewBreakdownItemData> breakdown;
}

class ReviewsLoadState {
  const ReviewsLoadState({
    required this.viewData,
    required this.isFromCache,
    required this.isStaleCache,
    required this.hasRemoteError,
    required this.isOffline,
    this.savedAt,
  });

  final ReviewsViewData viewData;
  final bool isFromCache;
  final bool isStaleCache;
  final bool hasRemoteError;
  final bool isOffline;
  final DateTime? savedAt;
}

class ReviewsOfflineException implements Exception {
  const ReviewsOfflineException();

  @override
  String toString() {
    return 'Connect to the internet to load reviews for the first time.';
  }
}

final reviewsMemoryCacheProvider =
    Provider<MemoryLruCache<String, LocalReviewsCacheModel>>((ref) {
      return MemoryLruCache<String, LocalReviewsCacheModel>(maxEntries: 8);
    });

final reviewsLocalDataSourceProvider = Provider<ReviewsLocalDataSource>((ref) {
  return ReviewsLocalDataSource(
    memoryCache: ref.watch(reviewsMemoryCacheProvider),
  );
});

final reviewsRemoteDataSourceProvider = Provider<ReviewsRemoteDataSource>((
  ref,
) {
  return ReviewsRemoteDataSource(firestore: FirebaseFirestore.instance);
});

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepositoryImpl(
    remoteDataSource: ref.watch(reviewsRemoteDataSourceProvider),
    localDataSource: ref.watch(reviewsLocalDataSourceProvider),
  );
});

final reviewsViewDataProvider =
    AsyncNotifierProvider.autoDispose<ReviewsNotifier, ReviewsLoadState>(
      ReviewsNotifier.new,
    );

final selectedReviewFilterProvider = StateProvider<ReviewFilter>(
  (ref) => ReviewFilter.all,
);

final filteredReviewsProvider = Provider<List<ReviewItemData>>((ref) {
  final state = ref.watch(reviewsViewDataProvider).valueOrNull;
  final filter = ref.watch(selectedReviewFilterProvider);
  final reviews = state?.viewData.reviews ?? const <ReviewItemData>[];

  return switch (filter) {
    ReviewFilter.all => reviews,
    ReviewFilter.asDriver =>
      reviews
          .where((review) => review.roleTag == ReviewRoleTag.driver)
          .toList(),
    ReviewFilter.asPassenger =>
      reviews
          .where((review) => review.roleTag == ReviewRoleTag.passenger)
          .toList(),
    ReviewFilter.recent => [...reviews],
  };
});

final reviewsSummaryProvider = Provider<String>((ref) {
  final state = ref.watch(reviewsViewDataProvider).valueOrNull;
  if (state == null) {
    return 'Loading reviews';
  }
  final user = state.viewData.user;
  return '${user.averageRating.toStringAsFixed(1)} average rating from ${user.totalReviews} reviews';
});

final reviewsCountProvider = Provider<int>(
  (ref) => ref.watch(filteredReviewsProvider).length,
);

class ReviewsNotifier extends AutoDisposeAsyncNotifier<ReviewsLoadState> {
  static const String _guestUserId = 'guest_reviews';
  static const String _guestUserName = 'Maria Gonzalez';
  static const Duration _connectivityCheckTimeout = Duration(seconds: 1);
  static const Duration _remoteLoadTimeout = Duration(seconds: 3);

  @override
  Future<ReviewsLoadState> build() async {
    final user = ref.watch(authUserProvider);
    ref.watch(connectivityStatusProvider);
    final isOnline = await _hasConnection();
    return _loadForUser(
      userId: user?.uid ?? _guestUserId,
      fallbackFullName: user?.fullName ?? _guestUserName,
      allowFreshCache: true,
      isOnline: isOnline,
    );
  }

  Future<void> refresh() async {
    final user = ref.read(authUserProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _loadForUser(
        userId: user?.uid ?? _guestUserId,
        fallbackFullName: user?.fullName ?? _guestUserName,
        allowFreshCache: false,
        isOnline: await _hasConnection(),
      );
    });
  }

  Future<void> clearCache() async {
    final user = ref.read(authUserProvider);
    await ref
        .read(reviewsRepositoryProvider)
        .clearCachedUserReviews(user?.uid ?? _guestUserId);
    ref.invalidateSelf();
  }

  Future<ReviewsLoadState> _loadForUser({
    required String userId,
    required String fallbackFullName,
    required bool allowFreshCache,
    required bool isOnline,
  }) async {
    final repository = ref.read(reviewsRepositoryProvider);
    final cached = await repository.getCachedUserReviews(userId);

    if (!isOnline) {
      if (cached != null) {
        return ReviewsLoadState(
          viewData: ReviewsViewData.fromEntity(cached.reviews),
          isFromCache: true,
          isStaleCache: cached.isExpired,
          hasRemoteError: false,
          isOffline: true,
          savedAt: cached.savedAt,
        );
      }

      throw const ReviewsOfflineException();
    }

    if (cached != null && allowFreshCache && !cached.isExpired) {
      return ReviewsLoadState(
        viewData: ReviewsViewData.fromEntity(cached.reviews),
        isFromCache: true,
        isStaleCache: false,
        hasRemoteError: false,
        isOffline: false,
        savedAt: cached.savedAt,
      );
    }

    if (cached != null) {
      state = AsyncData(
        ReviewsLoadState(
          viewData: ReviewsViewData.fromEntity(cached.reviews),
          isFromCache: true,
          isStaleCache: cached.isExpired,
          hasRemoteError: false,
          isOffline: false,
          savedAt: cached.savedAt,
        ),
      );
    }

    try {
      final liveReviews = await repository
          .getUserReviews(userId: userId, fallbackFullName: fallbackFullName)
          .timeout(_remoteLoadTimeout);
      return ReviewsLoadState(
        viewData: ReviewsViewData.fromEntity(liveReviews),
        isFromCache: false,
        isStaleCache: false,
        hasRemoteError: false,
        isOffline: false,
      );
    } catch (error) {
      if (cached != null) {
        final isStillOnline = await _hasConnection();
        return ReviewsLoadState(
          viewData: ReviewsViewData.fromEntity(cached.reviews),
          isFromCache: true,
          isStaleCache: true,
          hasRemoteError: true,
          isOffline: !isStillOnline || error is TimeoutException,
          savedAt: cached.savedAt,
        );
      }
      final isStillOnline = await _hasConnection();
      if (!isStillOnline || error is TimeoutException) {
        throw const ReviewsOfflineException();
      }
      rethrow;
    }
  }

  Future<bool> _hasConnection() {
    return ref
        .read(connectivityServiceProvider)
        .hasConnection()
        .timeout(_connectivityCheckTimeout, onTimeout: () => false);
  }
}
