import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/reviews_entity.dart';

class ReviewsModel extends ReviewsEntity {
  const ReviewsModel({
    required ReviewedUserModel super.user,
    required List<ReviewItemModel> super.reviews,
    required List<ReviewBreakdownItemModel> super.breakdown,
  });

  factory ReviewsModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final rawReviews = json['reviews'];
    final rawBreakdown = json['breakdown'];

    if (rawUser is! Map || rawReviews is! List || rawBreakdown is! List) {
      throw const FormatException('Invalid reviews payload.');
    }

    return ReviewsModel(
      user: ReviewedUserModel.fromJson(Map<String, dynamic>.from(rawUser)),
      reviews: rawReviews
          .map(
            (item) => ReviewItemModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      breakdown: rawBreakdown
          .map(
            (item) => ReviewBreakdownItemModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  factory ReviewsModel.sampleForUser({
    required String userId,
    required String fallbackFullName,
  }) {
    final name = fallbackFullName.trim().isEmpty
        ? 'Wheels User'
        : fallbackFullName.trim();
    final user = ReviewedUserModel(
      fullName: name,
      initials: _initialsForName(name),
      badgeLabel: 'Verified Student',
      memberSince: 'Member since Jan 2025',
      averageRating: 4.8,
      totalReviews: 5,
      supportingText: 'Highly rated by riders and drivers',
    );

    return ReviewsModel(
      user: user,
      reviews: const <ReviewItemModel>[
        ReviewItemModel(
          reviewerName: 'Carlos Mendez',
          reviewerInitials: 'CM',
          rating: 5,
          roleTag: ReviewRoleTag.passenger,
          dateLabel: '2 days ago',
          reviewText:
              'Very punctual, friendly, and made the ride feel safe and comfortable.',
        ),
        ReviewItemModel(
          reviewerName: 'Laura Perez',
          reviewerInitials: 'LP',
          rating: 5,
          roleTag: ReviewRoleTag.driver,
          dateLabel: '1 week ago',
          reviewText:
              'Excellent communication and very respectful during the whole trip.',
        ),
        ReviewItemModel(
          reviewerName: 'Andres Ruiz',
          reviewerInitials: 'AR',
          rating: 4,
          roleTag: ReviewRoleTag.passenger,
          dateLabel: '2 weeks ago',
          reviewText:
              'Very good experience overall. Organized and easy to coordinate with.',
        ),
        ReviewItemModel(
          reviewerName: 'Sofia Torres',
          reviewerInitials: 'ST',
          rating: 5,
          roleTag: ReviewRoleTag.driver,
          dateLabel: '3 weeks ago',
          reviewText:
              'Super reliable and kind. I would definitely ride with this user again.',
        ),
        ReviewItemModel(
          reviewerName: 'Juan Camilo',
          reviewerInitials: 'JC',
          rating: 5,
          roleTag: ReviewRoleTag.passenger,
          dateLabel: '1 month ago',
          reviewText:
              'Everything went smoothly. Great attitude and very trustworthy.',
        ),
      ],
      breakdown: const <ReviewBreakdownItemModel>[
        ReviewBreakdownItemModel(stars: 5, ratingCount: 4),
        ReviewBreakdownItemModel(stars: 4, ratingCount: 1),
        ReviewBreakdownItemModel(stars: 3, ratingCount: 0),
        ReviewBreakdownItemModel(stars: 2, ratingCount: 0),
        ReviewBreakdownItemModel(stars: 1, ratingCount: 0),
      ],
    );
  }

  factory ReviewsModel.emptyForUser({
    required String userId,
    required String fallbackFullName,
  }) {
    final name = fallbackFullName.trim().isEmpty
        ? 'Wheels User'
        : fallbackFullName.trim();

    return ReviewsModel(
      user: ReviewedUserModel(
        fullName: name,
        initials: _initialsForName(name),
        badgeLabel: 'Verified Student',
        memberSince: 'Member since Jan 2025',
        averageRating: 0,
        totalReviews: 0,
        supportingText: 'No reviews yet',
      ),
      reviews: const <ReviewItemModel>[],
      breakdown: const <ReviewBreakdownItemModel>[
        ReviewBreakdownItemModel(stars: 5, ratingCount: 0),
        ReviewBreakdownItemModel(stars: 4, ratingCount: 0),
        ReviewBreakdownItemModel(stars: 3, ratingCount: 0),
        ReviewBreakdownItemModel(stars: 2, ratingCount: 0),
        ReviewBreakdownItemModel(stars: 1, ratingCount: 0),
      ],
    );
  }

  factory ReviewsModel.fromFirestore({
    required String userId,
    required String fallbackFullName,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  }) {
    if (documents.isEmpty) {
      return ReviewsModel.emptyForUser(
        userId: userId,
        fallbackFullName: fallbackFullName,
      );
    }

    final sortedDocuments = [...documents]
      ..sort((left, right) {
        final leftDate = _dateTimeFromFirestore(left.data()['createdAt']);
        final rightDate = _dateTimeFromFirestore(right.data()['createdAt']);
        return rightDate.compareTo(leftDate);
      });
    final reviews = sortedDocuments
        .map((document) => ReviewItemModel.fromFirestore(document.data()))
        .toList();
    final breakdown = _buildBreakdown(reviews);
    final totalReviews = reviews.length;
    final averageRating = totalReviews == 0
        ? 0.0
        : reviews.fold<int>(0, (total, review) => total + review.rating) /
              totalReviews;
    final name = fallbackFullName.trim().isEmpty
        ? _readOptionalString(documents.first.data()['reviewedUserName']) ??
              'Wheels User'
        : fallbackFullName.trim();

    return ReviewsModel(
      user: ReviewedUserModel(
        fullName: name,
        initials: _initialsForName(name),
        badgeLabel: 'Verified Student',
        memberSince: 'Member since Jan 2025',
        averageRating: averageRating,
        totalReviews: totalReviews,
        supportingText: totalReviews == 0
            ? 'No reviews yet'
            : 'Highly rated by riders and drivers',
      ),
      reviews: reviews,
      breakdown: breakdown,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user': (user as ReviewedUserModel).toJson(),
      'reviews': reviews
          .map((review) => (review as ReviewItemModel).toJson())
          .toList(),
      'breakdown': breakdown
          .map((item) => (item as ReviewBreakdownItemModel).toJson())
          .toList(),
    };
  }
}

class ReviewedUserModel extends ReviewedUserEntity {
  const ReviewedUserModel({
    required super.fullName,
    required super.initials,
    required super.badgeLabel,
    required super.memberSince,
    required super.averageRating,
    required super.totalReviews,
    required super.supportingText,
  });

  factory ReviewedUserModel.fromJson(Map<String, dynamic> json) {
    return ReviewedUserModel(
      fullName: _readRequiredString(json['fullName'], 'fullName'),
      initials: _readRequiredString(json['initials'], 'initials'),
      badgeLabel: _readRequiredString(json['badgeLabel'], 'badgeLabel'),
      memberSince: _readRequiredString(json['memberSince'], 'memberSince'),
      averageRating: _readRequiredDouble(
        json['averageRating'],
        'averageRating',
      ),
      totalReviews: _readRequiredInt(json['totalReviews'], 'totalReviews'),
      supportingText: _readRequiredString(
        json['supportingText'],
        'supportingText',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fullName': fullName,
      'initials': initials,
      'badgeLabel': badgeLabel,
      'memberSince': memberSince,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'supportingText': supportingText,
    };
  }
}

class ReviewItemModel extends ReviewItemEntity {
  const ReviewItemModel({
    required super.reviewerName,
    required super.reviewerInitials,
    required super.rating,
    required super.roleTag,
    required super.dateLabel,
    required super.reviewText,
  });

  factory ReviewItemModel.fromJson(Map<String, dynamic> json) {
    return ReviewItemModel(
      reviewerName: _readRequiredString(json['reviewerName'], 'reviewerName'),
      reviewerInitials: _readRequiredString(
        json['reviewerInitials'],
        'reviewerInitials',
      ),
      rating: _readRequiredInt(json['rating'], 'rating'),
      roleTag: _roleTagFromStorage(
        _readRequiredString(json['roleTag'], 'roleTag'),
      ),
      dateLabel: _readRequiredString(json['dateLabel'], 'dateLabel'),
      reviewText: _readRequiredString(json['reviewText'], 'reviewText'),
    );
  }

  factory ReviewItemModel.fromFirestore(Map<String, dynamic> data) {
    final reviewerName =
        _readOptionalString(data['reviewerName']) ?? 'Wheels User';
    final createdAt = _dateTimeFromFirestore(data['createdAt']);
    return ReviewItemModel(
      reviewerName: reviewerName,
      reviewerInitials: _initialsForName(reviewerName),
      rating: (_readOptionalInt(data['rating']) ?? 5).clamp(1, 5),
      roleTag: _roleTagFromStorage(
        _readOptionalString(data['roleTag']) ??
            _readOptionalString(data['reviewedAs']) ??
            'passenger',
      ),
      dateLabel: _relativeDateLabel(createdAt),
      reviewText:
          _readOptionalString(data['reviewText']) ??
          _readOptionalString(data['comment']) ??
          'Great experience.',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'reviewerName': reviewerName,
      'reviewerInitials': reviewerInitials,
      'rating': rating,
      'roleTag': roleTag.storageValue,
      'dateLabel': dateLabel,
      'reviewText': reviewText,
    };
  }
}

class ReviewBreakdownItemModel extends ReviewBreakdownItemEntity {
  const ReviewBreakdownItemModel({
    required super.stars,
    required int ratingCount,
  }) : super(count: ratingCount);

  factory ReviewBreakdownItemModel.fromJson(Map<String, dynamic> json) {
    return ReviewBreakdownItemModel(
      stars: _readRequiredInt(json['stars'], 'stars'),
      ratingCount: _readRequiredInt(json['count'], 'count'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'stars': stars, 'count': this.count};
  }
}

extension ReviewRoleTagStorage on ReviewRoleTag {
  String get storageValue {
    return switch (this) {
      ReviewRoleTag.driver => 'driver',
      ReviewRoleTag.passenger => 'passenger',
    };
  }
}

ReviewRoleTag _roleTagFromStorage(String value) {
  return switch (value.trim().toLowerCase()) {
    'driver' || 'as_driver' => ReviewRoleTag.driver,
    _ => ReviewRoleTag.passenger,
  };
}

List<ReviewBreakdownItemModel> _buildBreakdown(List<ReviewItemModel> reviews) {
  return List<ReviewBreakdownItemModel>.generate(5, (index) {
    final stars = 5 - index;
    final ratingCount = reviews
        .where((review) => review.rating == stars)
        .length;
    return ReviewBreakdownItemModel(stars: stars, ratingCount: ratingCount);
  });
}

String _initialsForName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'WU';
  }
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _relativeDateLabel(DateTime value) {
  final difference = DateTime.now().toUtc().difference(value.toUtc());
  if (difference.inDays >= 30) {
    final months = (difference.inDays / 30).floor();
    return months == 1 ? '1 month ago' : '$months months ago';
  }
  if (difference.inDays >= 7) {
    final weeks = (difference.inDays / 7).floor();
    return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
  }
  if (difference.inDays > 0) {
    return difference.inDays == 1
        ? '1 day ago'
        : '${difference.inDays} days ago';
  }
  return 'Today';
}

DateTime _dateTimeFromFirestore(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now().toUtc();
  }
  return DateTime.now().toUtc();
}

String? _readOptionalString(Object? rawValue) {
  return rawValue is String && rawValue.trim().isNotEmpty
      ? rawValue.trim()
      : null;
}

int? _readOptionalInt(Object? rawValue) {
  return rawValue is num ? rawValue.toInt() : null;
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

double _readRequiredDouble(Object? rawValue, String fieldName) {
  if (rawValue is num) {
    return rawValue.toDouble();
  }
  throw FormatException('Invalid $fieldName value.');
}
