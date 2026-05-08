enum ReviewRoleTag { driver, passenger }

class ReviewedUserEntity {
  const ReviewedUserEntity({
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

class ReviewItemEntity {
  const ReviewItemEntity({
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

class ReviewBreakdownItemEntity {
  const ReviewBreakdownItemEntity({required this.stars, required this.count});

  final int stars;
  final int count;
}

class ReviewsEntity {
  const ReviewsEntity({
    required this.user,
    required this.reviews,
    required this.breakdown,
  });

  final ReviewedUserEntity user;
  final List<ReviewItemEntity> reviews;
  final List<ReviewBreakdownItemEntity> breakdown;
}

class ReviewsCacheSnapshot {
  const ReviewsCacheSnapshot({
    required this.reviews,
    required this.savedAt,
    required this.isExpired,
  });

  final ReviewsEntity reviews;
  final DateTime savedAt;
  final bool isExpired;
}
