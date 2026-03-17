import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';

class TrustViewData {
  const TrustViewData({
    required this.score,
    required this.headline,
    required this.headlineSubtitle,
    required this.metrics,
    required this.paymentReliability,
    required this.punctuality,
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
  final TrustPunctualityData punctuality;
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

class TrustPunctualityData {
  const TrustPunctualityData({
    required this.averageArrival,
    required this.averageDriverWait,
    required this.message,
  });

  final String averageArrival;
  final String averageDriverWait;
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

const _trustViewData = TrustViewData(
  score: 98,
  headline: 'Excellent Reliability!',
  headlineSubtitle: 'You\'re in the top 10% of users',
  metrics: [
    TrustMetricData(
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.accent,
      iconBackground: Color(0xFFEAFBF4),
      value: '15',
      label: 'On-time pays',
    ),
    TrustMetricData(
      icon: Icons.schedule_rounded,
      iconColor: AppColors.secondary,
      iconBackground: Color(0xFFEAF2FD),
      value: '94%',
      label: 'Punctual',
    ),
    TrustMetricData(
      icon: Icons.close_rounded,
      iconColor: AppColors.warning,
      iconBackground: Color(0xFFFFF3E8),
      value: '1',
      label: 'Cancelled',
    ),
  ],
  paymentReliability: TrustPaymentReliabilityData(
    completedPayments: 15,
    totalPayments: 16,
    successRateLabel: '94% payment success rate',
  ),
  punctuality: TrustPunctualityData(
    averageArrival: '2 min early',
    averageDriverWait: '1.5 min',
    message: 'Great punctuality! Keep it up',
  ),
  cancellation: TrustCancellationData(
    totalCancellations: 1,
    cancellationRate: '6%',
    note:
        'Multiple cancellations may affect your reliability score and access to rides.',
  ),
  policySteps: [
    TrustPolicyStepData(
      stepNumber: 1,
      stepColor: AppColors.accent,
      title: 'Free cancellation',
      description: 'Cancel up to 30 minutes before departure without penalty',
    ),
    TrustPolicyStepData(
      stepNumber: 2,
      stepColor: AppColors.warning,
      title: 'Late cancellation',
      description: 'Cancelling within 30 min results in a -10 point penalty',
    ),
    TrustPolicyStepData(
      stepNumber: 3,
      stepColor: Color(0xFFEF5A5A),
      title: 'No-show penalty',
      description: 'Not showing up: -25 points + temporary suspension',
    ),
  ],
  policyNotice:
      'Maintaining a reliability score above 85 is required to continue using Wheels. Repeated violations may result in permanent account suspension.',
  rewardPoints: 142,
  rewardItems: [
    TrustRewardItemData(label: 'On-time arrival', pointsLabel: '+5 pts'),
    TrustRewardItemData(label: 'Quick payment', pointsLabel: '+3 pts'),
    TrustRewardItemData(label: 'Positive review', pointsLabel: '+10 pts'),
  ],
);

final trustViewDataProvider = Provider<TrustViewData>((ref) => _trustViewData);

final trustStatusProvider = Provider<String>((ref) {
  final data = ref.watch(trustViewDataProvider);
  return '${data.score} trust score with ${data.rewardPoints} reward points.';
});

final trustPendingStepsProvider = Provider<int>(
  (ref) => ref.watch(trustViewDataProvider).policySteps.length,
);
