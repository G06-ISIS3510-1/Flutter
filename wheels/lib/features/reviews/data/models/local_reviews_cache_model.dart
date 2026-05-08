import '../../domain/entities/reviews_entity.dart';
import 'reviews_model.dart';

class LocalReviewsCacheModel {
  const LocalReviewsCacheModel({
    required this.version,
    required this.userId,
    required this.savedAt,
    required this.reviews,
  });

  static const int currentVersion = 1;

  final int version;
  final String userId;
  final DateTime savedAt;
  final ReviewsModel reviews;

  factory LocalReviewsCacheModel.create({
    required String userId,
    required ReviewsEntity reviews,
  }) {
    return LocalReviewsCacheModel(
      version: currentVersion,
      userId: userId,
      savedAt: DateTime.now().toUtc(),
      reviews: ReviewsModel(
        user: ReviewedUserModel(
          fullName: reviews.user.fullName,
          initials: reviews.user.initials,
          badgeLabel: reviews.user.badgeLabel,
          memberSince: reviews.user.memberSince,
          averageRating: reviews.user.averageRating,
          totalReviews: reviews.user.totalReviews,
          supportingText: reviews.user.supportingText,
        ),
        reviews: reviews.reviews
            .map(
              (review) => ReviewItemModel(
                reviewerName: review.reviewerName,
                reviewerInitials: review.reviewerInitials,
                rating: review.rating,
                roleTag: review.roleTag,
                dateLabel: review.dateLabel,
                reviewText: review.reviewText,
              ),
            )
            .toList(),
        breakdown: reviews.breakdown
            .map(
              (item) => ReviewBreakdownItemModel(
                stars: item.stars,
                ratingCount: item.count,
              ),
            )
            .toList(),
      ),
    );
  }

  factory LocalReviewsCacheModel.fromJson(Map<String, dynamic> json) {
    final version = _readRequiredInt(json['version'], 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported reviews cache version: $version');
    }

    final rawReviews = json['reviews'];
    if (rawReviews is! Map) {
      throw const FormatException('Invalid reviews cache payload.');
    }

    return LocalReviewsCacheModel(
      version: version,
      userId: _readRequiredString(json['userId'], 'userId'),
      savedAt: _parseRequiredDateTime(json['savedAt'], 'savedAt'),
      reviews: ReviewsModel.fromJson(Map<String, dynamic>.from(rawReviews)),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'userId': userId,
      'savedAt': savedAt.toIso8601String(),
      'reviews': reviews.toJson(),
    };
  }

  bool matchesUser(String currentUserId) {
    return userId == currentUserId;
  }

  bool isExpired({Duration maxAge = const Duration(minutes: 30)}) {
    final now = DateTime.now().toUtc();
    if (savedAt.isAfter(now.add(const Duration(minutes: 5)))) {
      return true;
    }
    return now.difference(savedAt.toUtc()) > maxAge;
  }

  ReviewsEntity toEntity() => reviews;
}

String _readRequiredString(Object? rawValue, String fieldName) {
  if (rawValue is String) {
    return rawValue;
  }
  throw FormatException('Invalid $fieldName value.');
}

int _readRequiredInt(Object? rawValue, String fieldName) {
  if (rawValue is num) {
    return rawValue.toInt();
  }
  throw FormatException('Invalid $fieldName value.');
}

DateTime _parseRequiredDateTime(Object? rawValue, String fieldName) {
  if (rawValue is! String) {
    throw FormatException('Invalid $fieldName value.');
  }

  final parsed = DateTime.tryParse(rawValue);
  if (parsed == null) {
    throw FormatException('Invalid $fieldName value.');
  }

  return parsed;
}
