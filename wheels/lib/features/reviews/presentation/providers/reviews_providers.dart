import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReviewRoleTag { driver, passenger }

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

  final String reviewerName;
  final String reviewerInitials;
  final int rating;
  final ReviewRoleTag roleTag;
  final String dateLabel;
  final String reviewText;
}

class ReviewBreakdownItemData {
  const ReviewBreakdownItemData({required this.stars, required this.count});

  final int stars;
  final int count;
}

class ReviewsViewData {
  const ReviewsViewData({
    required this.user,
    required this.reviews,
    required this.breakdown,
  });

  final ReviewedUserData user;
  final List<ReviewItemData> reviews;
  final List<ReviewBreakdownItemData> breakdown;
}

const _mockReviewsViewData = ReviewsViewData(
  user: ReviewedUserData(
    fullName: 'Maria Gonzalez',
    initials: 'MG',
    badgeLabel: 'Verified Student',
    memberSince: 'Member since Jan 2025',
    averageRating: 4.8,
    totalReviews: 5,
    supportingText: 'Highly rated by riders and drivers',
  ),
  reviews: [
    ReviewItemData(
      reviewerName: 'Carlos Mendez',
      reviewerInitials: 'CM',
      rating: 5,
      roleTag: ReviewRoleTag.passenger,
      dateLabel: '2 days ago',
      reviewText:
          'Maria was very punctual, friendly, and made the ride feel safe and comfortable.',
    ),
    ReviewItemData(
      reviewerName: 'Laura Perez',
      reviewerInitials: 'LP',
      rating: 5,
      roleTag: ReviewRoleTag.driver,
      dateLabel: '1 week ago',
      reviewText:
          'Excellent communication and very respectful during the whole trip.',
    ),
    ReviewItemData(
      reviewerName: 'Andres Ruiz',
      reviewerInitials: 'AR',
      rating: 4,
      roleTag: ReviewRoleTag.passenger,
      dateLabel: '2 weeks ago',
      reviewText:
          'Very good experience overall. She was organized and easy to coordinate with.',
    ),
    ReviewItemData(
      reviewerName: 'Sofia Torres',
      reviewerInitials: 'ST',
      rating: 5,
      roleTag: ReviewRoleTag.driver,
      dateLabel: '3 weeks ago',
      reviewText:
          'Super reliable and kind. I would definitely ride with her again.',
    ),
    ReviewItemData(
      reviewerName: 'Juan Camilo',
      reviewerInitials: 'JC',
      rating: 5,
      roleTag: ReviewRoleTag.passenger,
      dateLabel: '1 month ago',
      reviewText:
          'Everything went smoothly. Great attitude and very trustworthy.',
    ),
  ],
  breakdown: [
    ReviewBreakdownItemData(stars: 5, count: 4),
    ReviewBreakdownItemData(stars: 4, count: 1),
    ReviewBreakdownItemData(stars: 3, count: 0),
    ReviewBreakdownItemData(stars: 2, count: 0),
    ReviewBreakdownItemData(stars: 1, count: 0),
  ],
);

final reviewsViewDataProvider = Provider<ReviewsViewData>(
  (ref) => _mockReviewsViewData,
);

final selectedReviewFilterProvider = StateProvider<ReviewFilter>(
  (ref) => ReviewFilter.all,
);

final filteredReviewsProvider = Provider<List<ReviewItemData>>((ref) {
  final data = ref.watch(reviewsViewDataProvider);
  final filter = ref.watch(selectedReviewFilterProvider);

  return switch (filter) {
    ReviewFilter.all => data.reviews,
    ReviewFilter.asDriver =>
      data.reviews
          .where((review) => review.roleTag == ReviewRoleTag.driver)
          .toList(),
    ReviewFilter.asPassenger =>
      data.reviews
          .where((review) => review.roleTag == ReviewRoleTag.passenger)
          .toList(),
    ReviewFilter.recent => [...data.reviews],
  };
});

final reviewsSummaryProvider = Provider<String>((ref) {
  final user = ref.watch(reviewsViewDataProvider).user;
  return '${user.averageRating.toStringAsFixed(1)} average rating from ${user.totalReviews} reviews';
});

final reviewsCountProvider = Provider<int>(
  (ref) => ref.watch(filteredReviewsProvider).length,
);
