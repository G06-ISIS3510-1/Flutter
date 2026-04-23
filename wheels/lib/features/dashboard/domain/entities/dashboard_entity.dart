import '../../../rides/domain/entities/rides_entity.dart';
import '../../../wallet/domain/entities/wallet_summary.dart';

enum DashboardActionKind {
  none,
  searchRides,
  createRide,
  openRide,
  openPayment,
  openWallet,
}

class DashboardEntity {
  const DashboardEntity({
    required this.savedAt,
    required this.summary,
    required this.stats,
    required this.primaryUpdate,
    this.currentRide,
    this.walletSummary,
  });

  final DateTime savedAt;
  final String summary;
  final DashboardStatsEntity stats;
  final DashboardUpdateEntity primaryUpdate;
  final RidesEntity? currentRide;
  final WalletSummary? walletSummary;
}

class DashboardStatsEntity {
  const DashboardStatsEntity({
    required this.ridesValue,
    required this.scoreValue,
    required this.ratingValue,
  });

  final String ridesValue;
  final String scoreValue;
  final String ratingValue;
}

class DashboardUpdateEntity {
  const DashboardUpdateEntity({
    required this.title,
    required this.subtitle,
    required this.actionKind,
    this.actionLabel,
    this.rideId,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final DashboardActionKind actionKind;
  final String? actionLabel;
  final String? rideId;
  final String? trailing;
}
