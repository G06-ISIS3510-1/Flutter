import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/domain/entities/auth_entity.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/payments/domain/entities/payment_record.dart';
import '../../../../features/payments/presentation/providers/payment_provider.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/utils/app_formatter.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_theme_drawer.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../data/models/dashboard_model.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../../rides/domain/entities/rides_entity.dart';
import '../../../rides/presentation/models/ride_listing.dart';
import '../../../rides/presentation/providers/rides_providers.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _liveFetchTimeout = Duration(seconds: 8);

  DashboardEntity? _dashboardSnapshot;
  Object? _lastRefreshError;
  bool _isRefreshing = false;
  bool _isShowingFallback = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initializeDashboard);
  }

  Future<void> _initializeDashboard() async {
    await _restoreLatestDashboard();
    await _refreshDashboard(forceRefresh: true);
  }

  Future<void> _restoreLatestDashboard() async {
    final cache = await ref.read(dashboardLocalDataSourceProvider).loadLatestDashboard();
    if (!mounted || cache == null) {
      return;
    }

    setState(() {
      _dashboardSnapshot = cache;
      _isShowingFallback = true;
    });
  }

  Future<void> _refreshDashboard({
    bool forceRefresh = false,
    bool showRestoredMessage = false,
  }) async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      _lastRefreshError = null;
    });

    try {
      final isOnline = await ref.read(connectivityServiceProvider).hasConnection();
      if (!mounted) {
        return;
      }

      if (!isOnline) {
        setState(() {
          _isShowingFallback = _dashboardSnapshot != null;
          _lastRefreshError = _dashboardSnapshot == null
              ? 'Connection is unavailable and there is no saved dashboard on this device yet.'
              : null;
        });
        return;
      }

      final snapshot = await _loadLiveDashboard(forceRefresh: forceRefresh);
      if (!mounted) {
        return;
      }

      await ref
          .read(dashboardLocalDataSourceProvider)
          .saveLatestDashboard(DashboardModel.fromEntity(snapshot));
      if (!mounted) {
        return;
      }

      setState(() {
        _dashboardSnapshot = snapshot;
        _isShowingFallback = false;
        _lastRefreshError = null;
      });

      if (showRestoredMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection restored. Dashboard data is live again.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isShowingFallback = _dashboardSnapshot != null;
        _lastRefreshError = error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<DashboardEntity> _loadLiveDashboard({required bool forceRefresh}) async {
    final role = ref.read(currentUserRoleProvider);
    final user = ref.read(authUserProvider);

    if (role == UserRole.driver) {
      if (forceRefresh) {
        ref.invalidate(currentDriverRideProvider);
        ref.invalidate(driverWalletSummaryProvider);
      }

      final ride = await ref
          .read(currentDriverRideProvider.future)
          .timeout(_liveFetchTimeout);
      final walletSummary = await ref
          .read(driverWalletSummaryProvider.future)
          .timeout(_liveFetchTimeout);

      return DashboardEntity(
        savedAt: DateTime.now().toUtc(),
        summary: _buildSummary(role: role, ride: ride),
        stats: _buildStats(role: role, ride: ride),
        currentRide: ride,
        walletSummary: walletSummary,
        primaryUpdate: ride == null
            ? const DashboardUpdateEntity(
                title: 'No live ride yet',
                subtitle:
                    'Create a ride to start receiving passenger applications.',
                actionKind: DashboardActionKind.createRide,
                actionLabel: 'Create Ride',
              )
            : DashboardUpdateEntity(
                title: 'Manage your current ride',
                subtitle:
                    'Open your live trip and review the passenger group.',
                actionKind: DashboardActionKind.openRide,
                actionLabel: 'Open Ride',
                rideId: ride.id,
              ),
      );
    }

    if (forceRefresh) {
      ref.invalidate(currentPassengerRideProvider);
    }

    final ride = await ref
        .read(currentPassengerRideProvider.future)
        .timeout(_liveFetchTimeout);

    RideApplicationEntity? passengerApplication;
    PaymentRecord? paymentRecord;
    if (ride != null && user != null) {
      final paymentRequest = PaymentRecordRequest(
        rideId: ride.id,
        passengerId: user.uid,
      );
      if (forceRefresh) {
        ref.invalidate(passengerRideApplicationProvider(ride.id));
        ref.invalidate(paymentRecordStreamProvider(paymentRequest));
      }

      passengerApplication = await ref
          .read(passengerRideApplicationProvider(ride.id).future)
          .timeout(_liveFetchTimeout);
      paymentRecord = await ref
          .read(paymentRecordStreamProvider(paymentRequest).future)
          .timeout(_liveFetchTimeout);
    }

    return DashboardEntity(
      savedAt: DateTime.now().toUtc(),
      summary: _buildSummary(role: role, ride: ride),
      stats: _buildStats(role: role, ride: ride),
      currentRide: ride,
      primaryUpdate: _buildPassengerPrimaryUpdate(
        ride: ride,
        passengerApplication: passengerApplication,
        paymentRecord: paymentRecord,
        firstName: user?.fullName.split(RegExp(r'\s+')).first ?? 'User',
      ),
    );
  }

  DashboardStatsEntity _buildStats({
    required UserRole role,
    required RidesEntity? ride,
  }) {
    final ridesValue = switch (role) {
      UserRole.driver => ride == null ? '0' : '${ride.bookedSeats}',
      UserRole.admin => '0',
      UserRole.passenger => ride == null ? '0' : '1',
    };
    final scoreValue = ride == null ? '100%' : '${ride.onTimeRate}%';
    final ratingValue = ride == null
        ? '5.0'
        : ride.driverRating.toStringAsFixed(1);

    return DashboardStatsEntity(
      ridesValue: ridesValue,
      scoreValue: scoreValue,
      ratingValue: ratingValue,
    );
  }

  String _buildSummary({required UserRole role, required RidesEntity? ride}) {
    if (ride == null) {
      return role == UserRole.driver
          ? 'You do not have an active ride yet. Create one to start receiving passengers.'
          : 'You do not have an active ride yet. Search rides and apply from your dashboard.';
    }

    return role == UserRole.driver
        ? 'Your current ride from ${ride.origin} to ${ride.destination} departs at ${ride.departureLabel}.'
        : 'Your ride with ${ride.driverName} departs at ${ride.departureLabel} toward ${ride.destination}.';
  }

  DashboardUpdateEntity _buildPassengerPrimaryUpdate({
    required RidesEntity? ride,
    required RideApplicationEntity? passengerApplication,
    required PaymentRecord? paymentRecord,
    required String firstName,
  }) {
    if (ride == null) {
      return DashboardUpdateEntity(
        title: 'Welcome, $firstName',
        subtitle:
            'You do not have an active ride yet. Search available rides and apply to one first.',
        actionKind: DashboardActionKind.searchRides,
        actionLabel: 'Search Rides',
      );
    }

    final paymentStatus = paymentRecord?.effectiveStatus.trim().toLowerCase();
    final manualPaymentStatus =
        passengerApplication?.paymentStatus ?? RidePassengerPaymentStatus.pending;
    final selectedPaymentMethod =
        (passengerApplication?.paymentMethod ==
                    RidePassengerPaymentMethod.pendingSelection &&
                paymentRecord?.indicatesCardPaymentFlow == true)
            ? RidePassengerPaymentMethod.card
            : passengerApplication?.paymentMethod ??
                (ride.isManualTransferOnly
                    ? RidePassengerPaymentMethod.bankTransfer
                    : RidePassengerPaymentMethod.pendingSelection);
    final requiresPaymentSelection =
        ride.acceptsCardPayments &&
        selectedPaymentMethod == RidePassengerPaymentMethod.pendingSelection &&
        !(passengerApplication?.isPaymentLocked ?? false);
    final lockedWithoutPaymentMethod =
        selectedPaymentMethod == RidePassengerPaymentMethod.pendingSelection &&
        (passengerApplication?.isPaymentLocked ?? false);
    final usesCardPayment =
        selectedPaymentMethod == RidePassengerPaymentMethod.card;
    final isRidePaid = requiresPaymentSelection || lockedWithoutPaymentMethod
        ? false
        : usesCardPayment
            ? paymentStatus == 'approved'
            : manualPaymentStatus == RidePassengerPaymentStatus.paid;
    final isPaymentPending =
        requiresPaymentSelection || lockedWithoutPaymentMethod
            ? false
            : usesCardPayment
                ? paymentStatus == 'pending' || paymentStatus == 'in_process'
                : manualPaymentStatus == RidePassengerPaymentStatus.pending;
    final isPaymentExpired =
        usesCardPayment && paymentStatus == 'expired';

    return DashboardUpdateEntity(
      title: isRidePaid
          ? 'Ride already paid'
          : requiresPaymentSelection
              ? 'Choose your payment method'
              : lockedWithoutPaymentMethod
                  ? 'Payment marked unpaid'
                  : isPaymentPending
                      ? usesCardPayment
                          ? 'Payment under review'
                          : 'Waiting for transfer confirmation'
                      : isPaymentExpired
                          ? 'Payment expired'
                          : usesCardPayment
                              ? 'Payment needed'
                              : 'Transfer marked unpaid',
      subtitle: isRidePaid
          ? usesCardPayment
              ? 'Your ride with ${ride.driverName} was paid successfully.'
              : 'Your driver confirmed the transfer for this ride.'
          : requiresPaymentSelection
              ? 'Choose whether you will pay with card inside the app or transfer directly to ${ride.driverName}.'
              : lockedWithoutPaymentMethod
                  ? 'This ride finished before you selected a payment method, so your payment was marked as unpaid and locked.'
                  : isPaymentPending
                      ? usesCardPayment
                          ? 'We are still verifying the payment for your current ride.'
                          : 'Complete the transfer directly with ${ride.driverName}. They must confirm it before the ride can finish.'
                      : isPaymentExpired
                          ? 'The Mercado Pago checkout expired after 3 minutes. Open the payment screen to start a new checkout.'
                          : usesCardPayment
                              ? 'Complete the payment for ${ride.origin} to ${ride.destination}.'
                              : 'Your driver still has this transfer marked as unpaid.',
      actionKind: isRidePaid
          ? DashboardActionKind.openRide
          : DashboardActionKind.openPayment,
      actionLabel: isRidePaid
          ? 'View Ride'
          : requiresPaymentSelection
              ? 'Choose Method'
              : lockedWithoutPaymentMethod
                  ? 'View Payment'
                  : usesCardPayment
                      ? isPaymentPending
                          ? 'Open Payment'
                          : isPaymentExpired
                              ? 'Pay Again'
                              : 'Quick Pay'
                      : 'View Payment',
      rideId: ride.id,
      trailing: isRidePaid
          ? 'Paid'
          : requiresPaymentSelection
              ? 'Pending'
              : lockedWithoutPaymentMethod
                  ? 'Unpaid'
                  : isPaymentPending
                      ? 'Pending'
                      : isPaymentExpired
                          ? 'Expired'
                          : usesCardPayment
                              ? ride.priceLabel
                              : 'Unpaid',
    );
  }

  void _handleDashboardAction(DashboardActionKind actionKind, {String? rideId}) {
    switch (actionKind) {
      case DashboardActionKind.searchRides:
        context.go(AppRoutes.rides);
      case DashboardActionKind.createRide:
        context.go(AppRoutes.createRide);
      case DashboardActionKind.openRide:
        if (rideId == null) {
          return;
        }
        final role = ref.read(currentUserRoleProvider);
        context.go(
          role == UserRole.driver
              ? AppRoutes.activeRideById(rideId)
              : AppRoutes.rideDetailsById(rideId),
        );
      case DashboardActionKind.openPayment:
        if (rideId == null) {
          return;
        }
        context.go(AppRoutes.paymentByRideId(rideId));
      case DashboardActionKind.openWallet:
        context.go(AppRoutes.wallet);
      case DashboardActionKind.none:
        return;
    }
  }

  String _formatSavedAt(DateTime value) {
    final localValue = value.toLocal();
    final day = localValue.day.toString().padLeft(2, '0');
    final month = localValue.month.toString().padLeft(2, '0');
    final hour = localValue.hour.toString().padLeft(2, '0');
    final minute = localValue.minute.toString().padLeft(2, '0');
    return '$day/$month/${localValue.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(authUserProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final isOnline = connectivityAsync.valueOrNull ?? true;
    final fullName = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'Wheels User';
    final firstName = fullName.split(RegExp(r'\s+')).first;
    final snapshot = _dashboardSnapshot;

    ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
      final wasOnline = previous?.valueOrNull ?? true;
      final isNowOnline = next.valueOrNull ?? true;
      if (!wasOnline && isNowOnline) {
        unawaited(
          _refreshDashboard(forceRefresh: true, showRestoredMessage: true),
        );
      }
    });

    return AppScaffold(
      title: 'Dashboard',
      showAppBar: false,
      backgroundColor: palette.background,
      maxScrollableWidth: 440,
      scrollableHeader: _DashboardHeader(
        firstName: firstName,
        email: user?.email ?? 'No email available',
        stats: snapshot?.stats,
      ),
      drawer: const AppNavigationDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.home,
        role: role,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.s),
          if (_isShowingFallback || _lastRefreshError != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: _DashboardStatusBanner(
                isOnline: isOnline,
                isRefreshing: _isRefreshing,
                cachedAt: snapshot?.savedAt,
                hasCachedData: snapshot != null,
                error: _lastRefreshError,
                onRetry: isOnline && !_isRefreshing
                    ? () => _refreshDashboard(forceRefresh: true)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: _MapCard(),
          ),
          const SizedBox(height: AppSpacing.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: _CurrentRideCard(
              role: role,
              ride: snapshot?.currentRide,
              isShowingFallback: _isShowingFallback,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: _UpdatesSection(
              role: role,
              user: user,
              snapshot: snapshot,
              isShowingFallback: _isShowingFallback,
              onAction: _handleDashboardAction,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: snapshot == null
                ? Text(
                    _isRefreshing
                        ? 'Refreshing your dashboard data...'
                        : 'Connect to the internet to load your dashboard.',
                    style: TextStyle(color: palette.textSecondary),
                  )
                : Text(
                    _isShowingFallback
                        ? '${snapshot.summary} Cached on ${_formatSavedAt(snapshot.savedAt)}.'
                        : snapshot.summary,
                    style: TextStyle(color: palette.textSecondary),
                  ),
          ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.firstName,
    required this.email,
    this.stats,
  });

  final String firstName;
  final String email;
  final DashboardStatsEntity? stats;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.l,
      ),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => _CircleIconButton(
                  icon: Icons.menu,
                  onTap: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        color: palette.primaryForeground.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: TextStyle(
                        color: palette.primaryForeground,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.primaryForeground.withValues(
                          alpha: 0.72,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _CircleIconButton(
                icon: Icons.notifications_none,
                onTap: () => context.go(AppRoutes.notifications),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          _StatsRow(stats: stats),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({this.stats});

  final DashboardStatsEntity? stats;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final effectiveStats = stats ??
        const DashboardStatsEntity(
          ridesValue: '0',
          scoreValue: '100%',
          ratingValue: '5.0',
        );

    return Row(
      children: [
        Expanded(
          child: _StatCard(value: effectiveStats.ridesValue, label: 'Rides'),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: _StatCard(
            value: effectiveStats.scoreValue,
            label: 'Score',
            valueColor: palette.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: _StatCard(value: effectiveStats.ratingValue, label: 'Rating'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, this.valueColor});

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.primaryForeground.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? palette.primaryForeground,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: palette.primaryForeground.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.lg,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(painter: _GridPainter(palette: palette)),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(999),
                boxShadow: AppShadows.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: palette.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Campus rides',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.accent, width: 4),
                  boxShadow: AppShadows.lg,
                ),
                child: Icon(Icons.near_me, color: palette.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentRideCard extends StatelessWidget {
  const _CurrentRideCard({
    required this.role,
    required this.ride,
    required this.isShowingFallback,
  });

  final UserRole role;
  final RidesEntity? ride;
  final bool isShowingFallback;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (ride == null) {
      return _InfoCard(
        title: role == UserRole.driver ? 'Current Ride' : 'Passenger Home',
        subtitle: role == UserRole.driver
            ? 'You do not have an active ride yet.'
            : 'Search available rides and apply with your account.',
        actionLabel: role == UserRole.driver ? 'Create Ride' : 'Search Rides',
        onAction: () => context.go(
          role == UserRole.driver ? AppRoutes.createRide : AppRoutes.rides,
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.go(
        role == UserRole.driver
            ? AppRoutes.activeRideById(ride!.id)
            : AppRoutes.rideDetailsById(ride!.id),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppShadows.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    role == UserRole.driver ? 'Current Ride' : 'Your current ride',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    role == UserRole.driver
                        ? (ride!.isInProgress ? 'In Progress' : 'Open')
                        : (ride!.isInProgress ? 'In Progress' : 'Applied'),
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (isShowingFallback) ...[
              const SizedBox(height: 10),
              Text(
                'Cached ride details. Reconnect to confirm the latest availability.',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: palette.primaryLight,
                  child: Text(
                    ride!.driverInitials,
                    style: TextStyle(
                      color: palette.primaryForeground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride!.driverName,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role == UserRole.driver
                            ? '${ride!.availableSeats}/${ride!.totalSeats} seats left'
                            : 'Driver assigned to your ride',
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SmallActionButton(
                  icon: role == UserRole.driver
                      ? Icons.chat_bubble_outline
                      : Icons.payments_outlined,
                  onTap: () => context.go(
                    role == UserRole.driver
                        ? AppRoutes.groupChatByTripId(ride!.id)
                        : AppRoutes.paymentByRideId(ride!.id),
                  ),
                ),
                const SizedBox(width: 8),
                _SmallActionButton(
                  icon: Icons.arrow_forward_outlined,
                  onTap: () => context.go(
                    role == UserRole.driver
                        ? AppRoutes.activeRideById(ride!.id)
                        : AppRoutes.rideDetailsById(ride!.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: palette.border),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.trip_origin,
              iconColor: palette.secondary,
              label: 'Origin',
              value: ride!.origin,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              iconColor: palette.textSecondary,
              label: 'Destination',
              value: ride!.destination,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    title: 'Departure',
                    value: ride!.departureLabel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetric(title: 'Fare', value: ride!.priceLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdatesSection extends StatelessWidget {
  const _UpdatesSection({
    required this.role,
    required this.user,
    required this.snapshot,
    required this.isShowingFallback,
    required this.onAction,
  });

  final UserRole role;
  final AuthEntity? user;
  final DashboardEntity? snapshot;
  final bool isShowingFallback;
  final void Function(DashboardActionKind actionKind, {String? rideId}) onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Updates',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (snapshot != null)
          _UpdateCard(
            icon: role == UserRole.driver && snapshot!.currentRide != null
                ? Icons.people_alt_outlined
                : role == UserRole.driver
                    ? Icons.directions_car_outlined
                    : snapshot!.primaryUpdate.actionKind ==
                            DashboardActionKind.openPayment
                        ? Icons.payments_outlined
                        : snapshot!.primaryUpdate.actionKind ==
                                DashboardActionKind.openRide
                            ? Icons.check_circle_rounded
                            : Icons.search_outlined,
            iconBg: palette.accent,
            title: snapshot!.primaryUpdate.title,
            subtitle: snapshot!.primaryUpdate.subtitle,
            highlight: true,
            actionLabel: snapshot!.primaryUpdate.actionLabel,
            onAction: snapshot!.primaryUpdate.actionKind ==
                    DashboardActionKind.none
                ? null
                : () => onAction(
                      snapshot!.primaryUpdate.actionKind,
                      rideId: snapshot!.primaryUpdate.rideId,
                    ),
            trailing: snapshot!.primaryUpdate.trailing,
          )
        else
          _UpdateCard(
            icon: Icons.cloud_off_outlined,
            iconBg: palette.border,
            iconColor: palette.secondary,
            title: 'Dashboard unavailable',
            subtitle:
                'We could not load dashboard data yet. Reconnect and retry to fetch a fresh snapshot.',
          ),
        if (isShowingFallback) ...[
          const SizedBox(height: 10),
          _UpdateCard(
            icon: Icons.offline_bolt_outlined,
            iconBg: palette.secondary.withValues(alpha: 0.16),
            iconColor: palette.secondary,
            title: 'Offline fallback in use',
            subtitle:
                'The cards above are showing the latest saved dashboard data from this device.',
          ),
        ],
        if (role == UserRole.driver) ...[
          const SizedBox(height: 10),
          _UpdateCard(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: palette.border,
            iconColor: palette.secondary,
            title: 'Wallet balance',
            subtitle: snapshot?.walletSummary == null
                ? 'Open your driver wallet to see accumulated earnings.'
                : 'Available: ${AppFormatter.cop(snapshot!.walletSummary!.availableBalance)}. Pending withdrawals: ${AppFormatter.cop(snapshot!.walletSummary!.pendingWithdrawalBalance)}.',
            trailing: snapshot?.walletSummary == null
                ? null
                : AppFormatter.cop(snapshot!.walletSummary!.totalEarned),
            actionLabel: 'Open Wallet',
            onAction: () => onAction(DashboardActionKind.openWallet),
          ),
        ],
        const SizedBox(height: 10),
        _UpdateCard(
          icon: Icons.person_outline,
          iconBg: palette.border,
          iconColor: palette.secondary,
          title: 'Signed in account',
          subtitle: user?.email ?? 'No account data available.',
          trailing: role == UserRole.driver ? 'Driver' : 'Passenger',
        ),
      ],
    );
  }
}

class _DashboardStatusBanner extends StatelessWidget {
  const _DashboardStatusBanner({
    required this.isOnline,
    required this.isRefreshing,
    required this.hasCachedData,
    this.cachedAt,
    this.error,
    this.onRetry,
  });

  final bool isOnline;
  final bool isRefreshing;
  final bool hasCachedData;
  final DateTime? cachedAt;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final savedAtLabel = cachedAt == null
        ? null
        : _formatBannerSavedAt(cachedAt!);
    final title = !isOnline
        ? 'You are offline'
        : hasCachedData
            ? 'Showing cached dashboard data'
            : 'Dashboard refresh failed';
    final description = !isOnline
        ? hasCachedData
            ? savedAtLabel == null
                ? 'We loaded the latest dashboard saved on this device. Refresh once the connection returns.'
                : 'Last saved on $savedAtLabel. Refresh once the connection returns.'
            : 'There is no saved dashboard on this device yet.'
        : hasCachedData
            ? savedAtLabel == null
                ? 'A live refresh failed, so the latest cached dashboard remains visible.'
                : 'A live refresh failed, so the snapshot saved on $savedAtLabel remains visible.'
            : (error?.toString() ?? 'We could not load the dashboard right now.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.secondary.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_rounded, color: palette.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: palette.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.primary,
                side: BorderSide(color: palette.border),
              ),
              icon: isRefreshing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(isRefreshing ? 'Refreshing' : 'Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatBannerSavedAt(DateTime value) {
  final localValue = value.toLocal();
  final day = localValue.day.toString().padLeft(2, '0');
  final month = localValue.month.toString().padLeft(2, '0');
  final hour = localValue.hour.toString().padLeft(2, '0');
  final minute = localValue.minute.toString().padLeft(2, '0');
  return '$day/$month/${localValue.year} $hour:$minute';
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: palette.textSecondary)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.trailing,
    this.highlight = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconBg;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? trailing;
  final bool highlight;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? palette.accentSoft : palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight
              ? palette.accent.withValues(alpha: 0.35)
              : palette.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: iconColor ?? palette.primaryForeground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: palette.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (actionLabel != null && onAction != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [palette.accent, palette.accent.withBlue(140)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                color: palette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: palette.input,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: palette.primary),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: palette.primaryForeground.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: palette.primaryForeground),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.palette});

  final AppThemePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = palette.input;
    canvas.drawRect(Offset.zero & size, bg);

    final gridPaint = Paint()
      ..color = palette.border
      ..strokeWidth = 1;

    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pathPaint = Paint()
      ..color = palette.textSecondary.withValues(alpha: 0.75)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.45,
        size.width * 0.82,
        size.height * 0.35,
      );

    const dash = 10.0;
    const gap = 8.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          pathPaint,
        );
        distance += dash + gap;
      }
    }

    final pickupDot = Paint()..color = palette.secondary;
    canvas.drawCircle(
      Offset(size.width * 0.27, size.height * 0.78),
      5,
      pickupDot,
    );

    final rideDot = Paint()..color = palette.accent;
    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 0.48),
      8,
      rideDot,
    );

    final destinationDot = Paint()..color = palette.textPrimary;
    canvas.drawCircle(
      Offset(size.width * 0.83, size.height * 0.36),
      6,
      destinationDot,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}
