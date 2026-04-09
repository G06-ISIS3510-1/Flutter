import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/trust_remote_datasource.dart';
import '../../data/repositories/trust_repository_impl.dart';
import '../../domain/entities/trust_entity.dart';
import '../../domain/repositories/trust_repository.dart';

class TrustViewData {
  const TrustViewData({
    required this.score,
    required this.headline,
    required this.headlineSubtitle,
    required this.metrics,
    required this.paymentReliability,
    required this.consistency,
    required this.cancellation,
    required this.policySteps,
    required this.policyNotice,
    required this.rewardPoints,
    required this.rewardItems,
  });

  final int score;
  final String headline;
  final String headlineSubtitle;
  final List<TrustMetricData> metrics;
  final TrustPaymentReliabilityData paymentReliability;
  final TrustConsistencyData consistency;
  final TrustCancellationData cancellation;
  final List<TrustPolicyStepData> policySteps;
  final String policyNotice;
  final int rewardPoints;
  final List<TrustRewardItemData> rewardItems;
}

class TrustMetricData {
  const TrustMetricData({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String label;
}

class TrustPaymentReliabilityData {
  const TrustPaymentReliabilityData({
    required this.completedPayments,
    required this.totalPayments,
    required this.successRateLabel,
  });

  final int completedPayments;
  final int totalPayments;
  final String successRateLabel;
}

class TrustConsistencyData {
  const TrustConsistencyData({
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.message,
  });

  final String primaryLabel;
  final String primaryValue;
  final String secondaryLabel;
  final String secondaryValue;
  final String message;
}

class TrustCancellationData {
  const TrustCancellationData({
    required this.totalCancellations,
    required this.cancellationRate,
    required this.note,
  });

  final int totalCancellations;
  final String cancellationRate;
  final String note;
}

class TrustPolicyStepData {
  const TrustPolicyStepData({
    required this.stepNumber,
    required this.stepColor,
    required this.title,
    required this.description,
  });

  final int stepNumber;
  final Color stepColor;
  final String title;
  final String description;
}

class TrustRewardItemData {
  const TrustRewardItemData({required this.label, required this.pointsLabel});

  final String label;
  final String pointsLabel;
}

final trustRemoteDataSourceProvider = Provider<TrustRemoteDataSource>((ref) {
  return TrustRemoteDataSource(firestore: FirebaseFirestore.instance);
});

final trustRepositoryProvider = Provider<TrustRepository>((ref) {
  return TrustRepositoryImpl(
    remoteDataSource: ref.watch(trustRemoteDataSourceProvider),
  );
});

final currentTrustProvider = FutureProvider<TrustEntity>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) {
    throw StateError('You need to sign in to see your trust score.');
  }
  return ref.watch(trustRepositoryProvider).getTrustData(user.uid);
});

final trustViewDataProvider = FutureProvider<TrustViewData>((ref) async {
  final trust = await ref.watch(currentTrustProvider.future);
  return _mapTrustEntityToViewData(trust);
});

final trustStatusProvider = Provider<String>((ref) {
  final trust = ref.watch(currentTrustProvider).valueOrNull;
  if (trust == null) {
    return 'Trust score loading';
  }
  return '${trust.score} trust score with ${trust.rewardPoints} reward points.';
});

final trustPendingStepsProvider = Provider<int>(
  (ref) => _buildPolicySteps().length,
);

TrustViewData _mapTrustEntityToViewData(TrustEntity trust) {
  final headline = _headlineForScore(trust.score);
  final subtitle = _headlineSubtitle(trust);
  final maturityPoints = ((trust.accountAgeMonths * 2).clamp(0, 20)).toInt();
  final completionBonus =
      trust.totalRides >= 3 && trust.cancelledRides == 0 ? 20 : 0;

  return TrustViewData(
    score: trust.score,
    headline: headline,
    headlineSubtitle: subtitle,
    metrics: [
      TrustMetricData(
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.accent,
        iconBackground: const Color(0xFFEAFBF4),
        value: '${trust.completedRides}',
        label: 'Completed',
      ),
      TrustMetricData(
        icon: Icons.shield_outlined,
        iconColor: AppColors.secondary,
        iconBackground: const Color(0xFFEAF2FD),
        value: '${trust.score}%',
        label: 'Trust',
      ),
      TrustMetricData(
        icon: Icons.close_rounded,
        iconColor: AppColors.warning,
        iconBackground: const Color(0xFFFFF3E8),
        value: '${trust.cancelledRides}',
        label: 'Cancelled',
      ),
    ],
    paymentReliability: TrustPaymentReliabilityData(
      completedPayments: trust.approvedPayments,
      totalPayments: trust.totalPayments,
      successRateLabel: trust.hasPaymentHistory
          ? '${trust.paymentReliabilityPercent}% of your recorded payments were completed successfully.'
          : 'No payment history yet. For now, your score relies on ride activity and account maturity.',
    ),
    consistency: TrustConsistencyData(
      primaryLabel: trust.hasRideHistory ? 'Completion rate' : 'Ride history',
      primaryValue: trust.hasRideHistory
          ? '${trust.completionRatePercent}%'
          : 'No rides yet',
      secondaryLabel: 'Member since',
      secondaryValue: _formatMonthYear(trust.accountCreatedAt),
      message: _consistencyMessage(trust),
    ),
    cancellation: TrustCancellationData(
      totalCancellations: trust.cancelledRides,
      cancellationRate: '${trust.cancellationRatePercent}%',
      note: _cancellationNote(trust),
    ),
    policySteps: _buildPolicySteps(),
    policyNotice:
        'This score is calculated from completed rides, cancellations, payment resolution, and account maturity. Resolve pending activity quickly to keep a strong standing.',
    rewardPoints: trust.rewardPoints,
    rewardItems: [
      TrustRewardItemData(
        label: 'Completed rides',
        pointsLabel: '+${trust.completedRides * 5} pts',
      ),
      TrustRewardItemData(
        label: 'Approved payments',
        pointsLabel: '+${trust.approvedPayments * 3} pts',
      ),
      TrustRewardItemData(
        label: 'Account maturity',
        pointsLabel: '+$maturityPoints pts',
      ),
      TrustRewardItemData(
        label: 'Clean completion bonus',
        pointsLabel: '+$completionBonus pts',
      ),
    ],
  );
}

List<TrustPolicyStepData> _buildPolicySteps() {
  return const [
    TrustPolicyStepData(
      stepNumber: 1,
      stepColor: AppColors.accent,
      title: 'Complete confirmed rides',
      description:
          'Each completed ride adds trust and reward points to your profile.',
    ),
    TrustPolicyStepData(
      stepNumber: 2,
      stepColor: AppColors.warning,
      title: 'Resolve payments quickly',
      description:
          'Pending or unpaid ride payments reduce your score until they are resolved.',
    ),
    TrustPolicyStepData(
      stepNumber: 3,
      stepColor: Color(0xFFEF5A5A),
      title: 'Avoid unnecessary cancellations',
      description:
          'Repeated cancellations have the strongest negative effect on your standing.',
    ),
  ];
}

String _headlineForScore(int score) {
  if (score >= 90) {
    return 'Excellent Reliability!';
  }
  if (score >= 80) {
    return 'Strong Reliability';
  }
  if (score >= 70) {
    return 'Good Standing';
  }
  if (score >= 60) {
    return 'Building Trust';
  }
  return 'Needs Attention';
}

String _headlineSubtitle(TrustEntity trust) {
  if (!trust.hasRideHistory) {
    return 'Complete your first ride to start building a stronger score.';
  }
  if (trust.score >= 90 && trust.cancelledRides == 0 && trust.failedPayments == 0) {
    return 'Clean record across ${trust.totalRides} rides and resolved payments.';
  }
  if (trust.score >= 80) {
    return 'Your recent activity shows dependable behavior on the platform.';
  }
  if (trust.score >= 70) {
    return 'A few more completed rides will strengthen your standing quickly.';
  }
  return 'Reduce cancellations and unresolved payments to recover your score.';
}

String _consistencyMessage(TrustEntity trust) {
  if (!trust.hasRideHistory) {
    return 'Your score will become smarter as soon as you complete rides.';
  }
  if (trust.completionRatePercent >= 90) {
    return trust.isDriver
        ? 'Excellent completion pattern. Drivers with steady execution look more reliable.'
        : 'Excellent completion pattern. Keep confirming and finishing your rides.';
  }
  if (trust.completionRatePercent >= 75) {
    return 'Your consistency is solid, but avoiding cancellations would raise the score faster.';
  }
  return 'Focus on completing the next rides you join to recover your trust faster.';
}

String _cancellationNote(TrustEntity trust) {
  if (trust.cancelledRides == 0) {
    return 'Great job. You have no cancelled rides in your current history.';
  }
  if (trust.cancelledRides == 1) {
    return 'One cancellation is manageable, but repeated ones will lower your score noticeably.';
  }
  return 'Repeated cancellations reduce score faster than any other signal in the trust model.';
}

String _formatMonthYear(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.year}';
}
