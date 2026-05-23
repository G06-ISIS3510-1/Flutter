import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/cache/memory_lru_cache.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/trust_local_datasource.dart';
import '../../data/datasources/trust_remote_datasource.dart';
import '../../data/models/local_trust_cache_model.dart';
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

class TrustLoadState {
  const TrustLoadState({
    required this.trust,
    required this.viewData,
    required this.isFromCache,
    required this.isStaleCache,
    required this.hasRemoteError,
    required this.isOffline,
    this.savedAt,
  });

  final TrustEntity trust;
  final TrustViewData viewData;
  final bool isFromCache;
  final bool isStaleCache;
  final bool hasRemoteError;
  final bool isOffline;
  final DateTime? savedAt;
}

class TrustOfflineException implements Exception {
  const TrustOfflineException();

  @override
  String toString() {
    return 'Connect to the internet to calculate your trust score for the first time.';
  }
}

final trustMemoryCacheProvider =
    Provider<MemoryLruCache<String, LocalTrustCacheModel>>((ref) {
      return MemoryLruCache<String, LocalTrustCacheModel>(maxEntries: 8);
    });

final trustLocalDataSourceProvider = Provider<TrustLocalDataSource>((ref) {
  return TrustLocalDataSource(memoryCache: ref.watch(trustMemoryCacheProvider));
});

final trustRemoteDataSourceProvider = Provider<TrustRemoteDataSource>((ref) {
  return TrustRemoteDataSource(firestore: FirebaseFirestore.instance);
});

final trustRepositoryProvider = Provider<TrustRepository>((ref) {
  return TrustRepositoryImpl(
    remoteDataSource: ref.watch(trustRemoteDataSourceProvider),
    localDataSource: ref.watch(trustLocalDataSourceProvider),
  );
});

final trustLoadStateProvider =
    AsyncNotifierProvider.autoDispose<TrustNotifier, TrustLoadState>(
      TrustNotifier.new,
    );

final currentTrustProvider = Provider<AsyncValue<TrustEntity>>((ref) {
  return ref.watch(trustLoadStateProvider).whenData((state) => state.trust);
});

final trustViewDataProvider = Provider<AsyncValue<TrustLoadState>>((ref) {
  return ref.watch(trustLoadStateProvider);
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

class TrustNotifier extends AutoDisposeAsyncNotifier<TrustLoadState> {
  static const Duration _connectivityCheckTimeout = Duration(seconds: 1);
  static const Duration _remoteLoadTimeout = Duration(seconds: 4);

  @override
  Future<TrustLoadState> build() async {
    final user = ref.watch(authUserProvider);
    ref.watch(connectivityStatusProvider);
    if (user == null) {
      throw StateError('You need to sign in to see your trust score.');
    }

    return _loadForUser(
      userId: user.uid,
      allowFreshCache: true,
      isOnline: await _hasConnection(),
    );
  }

  Future<void> refresh() async {
    final user = ref.read(authUserProvider);
    if (user == null) {
      state = AsyncError(
        StateError('You need to sign in to see your trust score.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _loadForUser(
        userId: user.uid,
        allowFreshCache: false,
        isOnline: await _hasConnection(),
      );
    });
  }

  Future<void> clearCache() async {
    final user = ref.read(authUserProvider);
    if (user == null) {
      return;
    }
    await ref.read(trustRepositoryProvider).clearCachedTrustData(user.uid);
    ref.invalidateSelf();
  }

  Future<TrustLoadState> _loadForUser({
    required String userId,
    required bool allowFreshCache,
    required bool isOnline,
  }) async {
    final repository = ref.read(trustRepositoryProvider);
    final cached = await repository.getCachedTrustData(userId);

    if (!isOnline) {
      if (cached != null) {
        return _buildLoadState(
          trust: cached.trust,
          isFromCache: true,
          isStaleCache: cached.isExpired,
          hasRemoteError: false,
          isOffline: true,
          savedAt: cached.savedAt,
        );
      }

      throw const TrustOfflineException();
    }

    if (cached != null && allowFreshCache && !cached.isExpired) {
      return _buildLoadState(
        trust: cached.trust,
        isFromCache: true,
        isStaleCache: false,
        hasRemoteError: false,
        isOffline: false,
        savedAt: cached.savedAt,
      );
    }

    if (cached != null) {
      state = AsyncData(
        _buildLoadState(
          trust: cached.trust,
          isFromCache: true,
          isStaleCache: cached.isExpired,
          hasRemoteError: false,
          isOffline: false,
          savedAt: cached.savedAt,
        ),
      );
    }

    try {
      final liveTrust = await repository
          .getTrustData(userId)
          .timeout(_remoteLoadTimeout);
      return _buildLoadState(
        trust: liveTrust,
        isFromCache: false,
        isStaleCache: false,
        hasRemoteError: false,
        isOffline: false,
      );
    } catch (error) {
      if (cached != null) {
        final isStillOnline = await _hasConnection();
        return _buildLoadState(
          trust: cached.trust,
          isFromCache: true,
          isStaleCache: true,
          hasRemoteError: true,
          isOffline: !isStillOnline || error is TimeoutException,
          savedAt: cached.savedAt,
        );
      }

      final isStillOnline = await _hasConnection();
      if (!isStillOnline || error is TimeoutException) {
        throw const TrustOfflineException();
      }
      rethrow;
    }
  }

  TrustLoadState _buildLoadState({
    required TrustEntity trust,
    required bool isFromCache,
    required bool isStaleCache,
    required bool hasRemoteError,
    required bool isOffline,
    DateTime? savedAt,
  }) {
    return TrustLoadState(
      trust: trust,
      viewData: _mapTrustEntityToViewData(trust),
      isFromCache: isFromCache,
      isStaleCache: isStaleCache,
      hasRemoteError: hasRemoteError,
      isOffline: isOffline,
      savedAt: savedAt,
    );
  }

  Future<bool> _hasConnection() {
    return ref
        .read(connectivityServiceProvider)
        .hasConnection()
        .timeout(_connectivityCheckTimeout, onTimeout: () => false);
  }
}

TrustViewData _mapTrustEntityToViewData(TrustEntity trust) {
  final headline = _headlineForScore(trust.score);
  final subtitle = _headlineSubtitle(trust);
  final maturityPoints = ((trust.accountAgeMonths * 2).clamp(0, 20)).toInt();
  final completionBonus = trust.totalRides >= 3 && trust.cancelledRides == 0
      ? 20
      : 0;

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
  if (trust.score >= 90 &&
      trust.cancelledRides == 0 &&
      trust.failedPayments == 0) {
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
