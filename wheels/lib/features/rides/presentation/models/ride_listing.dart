import 'package:flutter/material.dart';

class RideListing {
  const RideListing({
    required this.id,
    required this.driverName,
    required this.driverInitials,
    required this.rating,
    required this.reviewCount,
    required this.origin,
    required this.destination,
    required this.departureDateTime,
    required this.durationMinutes,
    required this.pricePerSeat,
    required this.seatsLeft,
    required this.onTimeRate,
    required this.verifiedByUniversity,
  });

  final String id;
  final String driverName;
  final String driverInitials;
  final double rating;
  final int reviewCount;
  final String origin;
  final String destination;
  final DateTime departureDateTime;
  final int durationMinutes;
  final int pricePerSeat;
  final int seatsLeft;
  final int onTimeRate;
  final bool verifiedByUniversity;

  String get departureLabel {
    final hour = departureDateTime.hour.toString().padLeft(2, '0');
    final minute = departureDateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get durationLabel => '$durationMinutes min';

  String get priceLabel => '\$${(pricePerSeat / 1000).toStringAsFixed(1)}k';

  String get dateLabel {
    final day = departureDateTime.day.toString().padLeft(2, '0');
    final month = departureDateTime.month.toString().padLeft(2, '0');
    final year = departureDateTime.year.toString();
    return '$day/$month/$year';
  }
}

enum RideSortOption { earliest, cheapest, highestRated }

extension RideSortOptionLabel on RideSortOption {
  String get label => switch (this) {
    RideSortOption.earliest => 'Earliest',
    RideSortOption.cheapest => 'Cheapest',
    RideSortOption.highestRated => 'Highest Rated',
  };

  IconData get icon => switch (this) {
    RideSortOption.earliest => Icons.schedule_outlined,
    RideSortOption.cheapest => Icons.sell_outlined,
    RideSortOption.highestRated => Icons.star_outline,
  };
}
