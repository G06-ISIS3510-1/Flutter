class TrustEntity {
  const TrustEntity({
    required this.userId,
    required this.role,
    required this.accountCreatedAt,
    required this.totalRides,
    required this.completedRides,
    required this.cancelledRides,
    required this.activeRides,
    required this.totalPayments,
    required this.approvedPayments,
    required this.pendingPayments,
    required this.failedPayments,
    required this.score,
    required this.rewardPoints,
  });

  final String userId;
  final String role;
  final DateTime accountCreatedAt;
  final int totalRides;
  final int completedRides;
  final int cancelledRides;
  final int activeRides;
  final int totalPayments;
  final int approvedPayments;
  final int pendingPayments;
  final int failedPayments;
  final int score;
  final int rewardPoints;

  bool get isDriver => role == 'driver';
  bool get hasRideHistory => totalRides > 0;
  bool get hasPaymentHistory => totalPayments > 0;

  double get completionRate {
    if (totalRides == 0) {
      return 0;
    }
    return completedRides / totalRides;
  }

  int get completionRatePercent => (completionRate * 100).round();

  double get paymentReliabilityRate {
    if (totalPayments == 0) {
      return 0;
    }
    return approvedPayments / totalPayments;
  }

  int get paymentReliabilityPercent =>
      (paymentReliabilityRate * 100).round().clamp(0, 100).toInt();

  int get cancellationRatePercent {
    if (totalRides == 0) {
      return 0;
    }
    return ((cancelledRides / totalRides) * 100).round().clamp(0, 100).toInt();
  }

  int get accountAgeDays {
    final difference = DateTime.now().difference(accountCreatedAt).inDays;
    return difference < 0 ? 0 : difference;
  }

  int get accountAgeMonths => accountAgeDays ~/ 30;
}
