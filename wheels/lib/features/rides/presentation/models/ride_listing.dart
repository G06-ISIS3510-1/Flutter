import 'package:flutter/material.dart';

import '../../domain/entities/rides_entity.dart';

enum RideSortOption { smartMatch, earliest, cheapest, highestRated }

extension RideSortOptionLabel on RideSortOption {
  String get label => switch (this) {
    RideSortOption.smartMatch => 'Smart Match',
    RideSortOption.earliest => 'Earliest',
    RideSortOption.cheapest => 'Cheapest',
    RideSortOption.highestRated => 'Highest Rated',
  };

  IconData get icon => switch (this) {
    RideSortOption.smartMatch => Icons.auto_awesome_outlined,
    RideSortOption.earliest => Icons.schedule_outlined,
    RideSortOption.cheapest => Icons.sell_outlined,
    RideSortOption.highestRated => Icons.star_outline,
  };
}

extension RidePresentation on RidesEntity {
  String get departureLabel {
    final hour = departureAt.hour.toString().padLeft(2, '0');
    final minute = departureAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get durationLabel => '$estimatedDurationMinutes min';

  String get priceLabel => '\$${(pricePerSeat / 1000).toStringAsFixed(1)}k';

  String get dateLabel {
    final day = departureAt.day.toString().padLeft(2, '0');
    final month = departureAt.month.toString().padLeft(2, '0');
    final year = departureAt.year.toString();
    return '$day/$month/$year';
  }
}
