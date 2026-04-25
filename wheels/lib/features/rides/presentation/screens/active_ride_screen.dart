import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/payments/domain/entities/payment_record.dart';
import '../../../../features/payments/presentation/providers/payment_provider.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/services/navigation_launcher_service.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../data/models/local_pending_ride_status_action_model.dart';
import '../../domain/entities/rides_entity.dart';
import '../models/ride_listing.dart';
import '../providers/rides_providers.dart';

class ActiveRideScreen extends ConsumerStatefulWidget {
  const ActiveRideScreen({this.rideId, super.key});

  static const _navigationLauncher = NavigationLauncherService();

  final String? rideId;

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  LocalPendingRideStatusActionModel? _pendingStatusAction;
  bool _isRestoringPendingAction = false;
  bool _isSyncingPendingAction = false;
  String? _loadedPendingActionRideId;
  StreamSubscription<bool>? _connectivitySubscription;

  static const _navigationLauncher = NavigationLauncherService();

  String? get rideId => widget.rideId;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = ref
        .read(connectivityServiceProvider)
        .watchConnection()
        .listen((isOnline) {
          if (isOnline && mounted) {
            unawaited(_attemptPendingStatusSync(triggeredAutomatically: true));
          }
        });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _ensurePendingActionForRide(String rideId) async {
    if (_loadedPendingActionRideId == rideId || _isRestoringPendingAction) {
      return;
    }

    setState(() {
      _isRestoringPendingAction = true;
    });

    final pendingAction = await ref
        .read(activeRidePendingActionLocalDataSourceProvider)
        .loadPendingAction(rideId: rideId);

    if (!mounted) {
      return;
    }

    setState(() {
      _pendingStatusAction = pendingAction;
      _loadedPendingActionRideId = rideId;
      _isRestoringPendingAction = false;
    });
  }

  Future<void> _persistPendingStatusAction({
    required String rideId,
    required String targetStatus,
    required String lastKnownStatus,
  }) async {
    final action = LocalPendingRideStatusActionModel.create(
      rideId: rideId,
      targetStatus: targetStatus,
      lastKnownStatus: lastKnownStatus,
    );

    await ref
        .read(activeRidePendingActionLocalDataSourceProvider)
        .savePendingAction(action);

    if (!mounted) {
      return;
    }

    setState(() {
      _pendingStatusAction = action;
      _loadedPendingActionRideId = rideId;
      _isSyncingPendingAction = false;
    });
  }

  Future<void> _clearPendingStatusAction({String? rideId}) async {
    final targetRideId = rideId ?? _pendingStatusAction?.rideId;
    if (targetRideId == null) {
      if (mounted) {
        setState(() {
          _pendingStatusAction = null;
          _isSyncingPendingAction = false;
        });
      }
      return;
    }

    await ref
        .read(activeRidePendingActionLocalDataSourceProvider)
        .clearPendingAction(rideId: targetRideId);

    if (!mounted) {
      return;
    }

    setState(() {
      _pendingStatusAction = null;
      _isSyncingPendingAction = false;
      if (_loadedPendingActionRideId == targetRideId) {
        _loadedPendingActionRideId = targetRideId;
      }
    });
  }

  bool _looksLikeConnectivityFailure(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout') ||
        message.contains('connection') ||
        message.contains('unavailable');
  }

  String _pendingActionLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'Ride start pending sync';
      case 'cancelled':
        return 'Ride cancellation pending sync';
      default:
        return 'Ride status update pending sync';
    }
  }

  String _pendingActionMessage(String status) {
    switch (status) {
      case 'in_progress':
        return 'The ride will start automatically when connectivity returns.';
      case 'cancelled':
        return 'The ride will be cancelled automatically when connectivity returns.';
      default:
        return 'This ride status update will be sent when connectivity returns.';
    }
  }

  String _formatPendingSavedAt(DateTime savedAt) {
    final date = '${savedAt.day}/${savedAt.month}/${savedAt.year}';
    final hour = TimeOfDay.fromDateTime(savedAt).format(context);
    return '$date at $hour';
  }

  Future<void> _attemptPendingStatusSync({
    required bool triggeredAutomatically,
  }) async {
    final pendingAction = _pendingStatusAction;
    if (pendingAction == null || _isSyncingPendingAction) {
      return;
    }

    final hasConnection = await ref
        .read(connectivityServiceProvider)
        .hasConnection();
    if (!hasConnection) {
      return;
    }

    if (mounted) {
      setState(() {
        _isSyncingPendingAction = true;
      });
    }

    try {
      await ref
          .read(rideStatusControllerProvider.notifier)
          .updateRideStatus(
            rideId: pendingAction.rideId,
            status: pendingAction.targetStatus,
          );
      ref.read(rideStatusControllerProvider.notifier).clear();
      await _clearPendingStatusAction(rideId: pendingAction.rideId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              triggeredAutomatically
                  ? 'Pending ride action synced successfully.'
                  : 'Ride action synced successfully.',
            ),
          ),
        );

      if (pendingAction.targetStatus == 'cancelled') {
        context.go(AppRoutes.dashboard);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSyncingPendingAction = false;
      });

      if (!_looksLikeConnectivityFailure(error)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'We could not sync the pending ride action yet: $error',
              ),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final rideAsync = rideId == null
        ? ref.watch(currentDriverRideProvider)
        : ref.watch(rideProvider(rideId!));

    ref.listen<AsyncValue<void>>(rideStatusControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });
    ref.listen<AsyncValue<void>>(ridePaymentControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    return AppScaffold(
      title: 'Active Ride',
      showAppBar: false,
      backgroundColor: palette.background,
      bottomNavigationBar: const AppBottomNav(
        currentTab: AppBottomNavTab.middle,
        role: UserRole.driver,
      ),
      child: rideAsync.when(
        data: (ride) {
          if (ride == null) {
            return _EmptyActiveRide(
              onCreateRide: () => context.go(AppRoutes.createRide),
            );
          }

          if (_loadedPendingActionRideId != ride.id && !_isRestoringPendingAction) {
            Future<void>.microtask(() => _ensurePendingActionForRide(ride.id));
          }

          final pendingAction = _pendingStatusAction;
          if (pendingAction != null && pendingAction.rideId == ride.id) {
            if (ride.status == pendingAction.targetStatus) {
              Future<void>.microtask(
                () => _clearPendingStatusAction(rideId: ride.id),
              );
            } else if (ride.status != pendingAction.lastKnownStatus) {
              Future<void>.microtask(
                () => _clearPendingStatusAction(rideId: ride.id),
              );
            }
          }

          final applicationsAsync = ref.watch(
            rideApplicationsProvider(ride.id),
          );
          final statusState = ref.watch(rideStatusControllerProvider);
          final paymentState = ref.watch(ridePaymentControllerProvider);
          final hasPendingStatusAction =
              pendingAction != null && pendingAction.rideId == ride.id;
          final pendingActionForRide = hasPendingStatusAction
              ? pendingAction!
              : null;
          final isLoading =
              statusState.isLoading ||
              paymentState.isLoading ||
              _isSyncingPendingAction;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              _headerCard(
                context,
                ride,
                statusOverride: pendingActionForRide?.targetStatus,
              ),
              const SizedBox(height: AppSpacing.m),
              _routeCard(context, ride),
              if (hasPendingStatusAction) ...[
                const SizedBox(height: AppSpacing.m),
                _pendingStatusActionCard(
                  context: context,
                  pendingAction: pendingActionForRide!,
                  isSyncing: _isSyncingPendingAction,
                ),
              ],
              const SizedBox(height: AppSpacing.m),
              applicationsAsync.when(
                data: (applications) => _statusActions(
                  context: context,
                  ref: ref,
                  ride: ride,
                  applications: applications,
                  isLoading: isLoading,
                  hasPendingStatusAction: hasPendingStatusAction,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _errorCard(
                  context,
                  'We could not load passenger applications.',
                  error.toString(),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              applicationsAsync.when(
                data: (applications) =>
                    _passengerSection(context, ride, applications),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _errorCard(
                  context,
                  'We could not load passenger applications.',
                  error.toString(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _errorCard(
          context,
          'We could not load your current ride.',
          error.toString(),
        ),
      ),
    );
  }

  Widget _headerCard(
    BuildContext context,
    RidesEntity ride, {
    String? statusOverride,
  }) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.primary, palette.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: palette.primaryForeground.withValues(alpha: 0.18),
            child: Text(
              ride.driverInitials,
              style: TextStyle(
                color: palette.primaryForeground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.driverName,
                  style: TextStyle(
                    color: palette.primaryForeground,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${ride.availableSeats}/${ride.totalSeats} seats available',
                  style: TextStyle(
                    color: palette.primaryForeground.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: palette.primaryForeground.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Text(
              _rideStatusLabel(statusOverride ?? ride.status),
              style: TextStyle(
                color: palette.primaryForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(BuildContext context, RidesEntity ride) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ride details',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          _InfoRow(Icons.trip_origin, 'Origin', ride.origin),
          const SizedBox(height: AppSpacing.s),
          _InfoRow(Icons.place_outlined, 'Destination', ride.destination),
          const SizedBox(height: AppSpacing.s),
          _InfoRow(Icons.calendar_month_outlined, 'Date', ride.dateLabel),
          const SizedBox(height: AppSpacing.s),
          _InfoRow(Icons.schedule_outlined, 'Departure', ride.departureLabel),
          const SizedBox(height: AppSpacing.s),
          _InfoRow(Icons.timer_outlined, 'Duration', ride.durationLabel),
          const SizedBox(height: AppSpacing.s),
          _InfoRow(
            Icons.attach_money,
            'Price per seat',
            '\$${ride.pricePerSeat}',
          ),
          const SizedBox(height: AppSpacing.s),
          _InfoRow(
            ride.acceptsCardPayments
                ? Icons.credit_card_outlined
                : Icons.account_balance_outlined,
            'Payment',
            ride.paymentOptionLabel,
          ),
          if (ride.notes.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            _InfoRow(Icons.notes_outlined, 'Notes', ride.notes),
          ],
        ],
      ),
    );
  }

  Widget _pendingStatusActionCard({
    required BuildContext context,
    required LocalPendingRideStatusActionModel pendingAction,
    required bool isSyncing,
  }) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.warning.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _pendingActionLabel(pendingAction.targetStatus),
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _pendingActionMessage(pendingAction.targetStatus),
            style: TextStyle(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Saved ${_formatPendingSavedAt(pendingAction.savedAt)}',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              ElevatedButton.icon(
                onPressed: isSyncing
                    ? null
                    : () => _attemptPendingStatusSync(
                        triggeredAutomatically: false,
                      ),
                icon: Icon(
                  isSyncing ? Icons.sync : Icons.cloud_upload_outlined,
                ),
                label: Text(isSyncing ? 'Syncing...' : 'Retry Sync'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.warning,
                  foregroundColor: palette.textPrimary,
                ),
              ),
              OutlinedButton.icon(
                onPressed: isSyncing
                    ? null
                    : () => _clearPendingStatusAction(
                        rideId: pendingAction.rideId,
                      ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Discard Pending Action'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusActions({
    required BuildContext context,
    required WidgetRef ref,
    required RidesEntity ride,
    required List<RideApplicationEntity> applications,
    required bool isLoading,
    required bool hasPendingStatusAction,
  }) {
    Future<void> openNavigation() async {
      final opened = await _navigationLauncher.openDrivingDirections(
        destination: ride.destination,
      );

      if (!context.mounted) {
        return;
      }

      if (!opened) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('We could not open Google Maps for this route.'),
            ),
          );
      }
    }

    Future<void> updateStatus(String status, String successMessage) async {
      if (hasPendingStatusAction) {
        return;
      }

      final hasConnection = await ref
          .read(connectivityServiceProvider)
          .hasConnection();
      if (!hasConnection) {
        if (status == 'completed') {
          if (!context.mounted) {
            return;
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Finishing a ride requires an internet connection because passenger payment updates must be saved live.',
                ),
              ),
            );
          return;
        }

        await _persistPendingStatusAction(
          rideId: ride.id,
          targetStatus: status,
          lastKnownStatus: ride.status,
        );

        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                status == 'in_progress'
                    ? 'Ride start saved locally. It will sync when you reconnect.'
                    : 'Ride cancellation saved locally. It will sync when you reconnect.',
              ),
            ),
          );
        return;
      }

      try {
        await ref
            .read(rideStatusControllerProvider.notifier)
            .updateRideStatus(rideId: ride.id, status: status);
      } catch (error) {
        if (status != 'completed' && _looksLikeConnectivityFailure(error)) {
          await _persistPendingStatusAction(
            rideId: ride.id,
            targetStatus: status,
            lastKnownStatus: ride.status,
          );

          if (!context.mounted) {
            return;
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  status == 'in_progress'
                      ? 'Ride start saved locally after a connection issue. It will sync automatically later.'
                      : 'Ride cancellation saved locally after a connection issue. It will sync automatically later.',
                ),
              ),
            );
          return;
        }

        rethrow;
      }

      if (!context.mounted) {
        return;
      }

      ref.read(rideStatusControllerProvider.notifier).clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));

      if (status == 'in_progress') {
        await openNavigation();
      }

      if (!context.mounted) {
        return;
      }

      if (status == 'cancelled' || status == 'completed') {
        context.go(AppRoutes.dashboard);
      }
    }

    Future<void> finishRide() async {
      final cardPaymentStatuses = ride.acceptsCardPayments
          ? await _loadCardPaymentStatuses(ref, ride, applications)
          : null;
      if (!context.mounted) {
        return;
      }

      final review = await _openPassengerReviewFlow(
        context,
        ride,
        applications,
        cardPaymentStatuses,
      );
      if (review == null) {
        return;
      }

      for (final application in applications) {
        if (application.usesCardPayment) {
          continue;
        }

        final reviewedStatus =
            review.paymentStatuses[application.id] ??
            RidePassengerPaymentStatus.pending;
        final finalPaymentStatus =
            reviewedStatus == RidePassengerPaymentStatus.paid
            ? RidePassengerPaymentStatus.paid
            : RidePassengerPaymentStatus.unpaid;
        final paymentMethod = application.paymentMethod;
        final paymentStatusSource =
            application.usesCardPayment &&
                finalPaymentStatus == RidePassengerPaymentStatus.paid
            ? 'mercado_pago'
            : application.usesManualTransfer &&
                  finalPaymentStatus == RidePassengerPaymentStatus.paid
            ? 'driver_manual'
            : 'ride_completion_auto';
        await ref
            .read(ridePaymentControllerProvider.notifier)
            .updatePassengerPaymentStatus(
              rideId: ride.id,
              passengerId: application.id,
              paymentMethod: paymentMethod,
              paymentStatus: finalPaymentStatus,
              isPaymentLocked: true,
              paymentStatusSource: paymentStatusSource,
            );
      }

      ref.read(ridePaymentControllerProvider.notifier).clear();
      await updateStatus(
        'completed',
        'Ride finished and manual payment statuses were saved.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => context.go(AppRoutes.groupChatByTripId(ride.id)),
          icon: const Icon(Icons.forum_outlined),
          label: const Text('Open Group Chat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.palette.secondary,
            foregroundColor: context.palette.primaryForeground,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        if (ride.status == 'open')
          ElevatedButton(
            onPressed: isLoading || hasPendingStatusAction
                ? null
                : () =>
                      updateStatus('in_progress', 'Ride started successfully.'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.accent,
              foregroundColor: context.palette.accentForeground,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(isLoading ? 'Updating...' : 'Start Ride'),
          ),
        if (ride.status == 'in_progress') ...[
          const SizedBox(height: AppSpacing.s),
          ElevatedButton.icon(
            onPressed: isLoading || hasPendingStatusAction
                ? null
                : openNavigation,
            icon: const Icon(Icons.navigation_outlined),
            label: const Text('Open Navigation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.secondary,
              foregroundColor: context.palette.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          OutlinedButton.icon(
            onPressed: isLoading || hasPendingStatusAction ? null : finishRide,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(isLoading ? 'Updating...' : 'Finish Ride'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        OutlinedButton(
          onPressed:
              isLoading || ride.status == 'completed' || hasPendingStatusAction
              ? null
              : () => updateStatus('cancelled', 'Ride cancelled.'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: const Text('Cancel Ride'),
        ),
      ],
    );
  }

  Future<_RideCompletionReviewResult?> _openPassengerReviewFlow(
    BuildContext context,
    RidesEntity ride,
    List<RideApplicationEntity> applications,
    Map<String, RidePassengerPaymentStatus>? cardPaymentStatuses,
  ) async {
    if (applications.isEmpty) {
      return const _RideCompletionReviewResult(
        <String, RidePassengerPaymentStatus>{},
      );
    }

    final ratings = <String, int>{
      for (final application in applications) application.id: 5,
    };
    final paymentStatuses = <String, RidePassengerPaymentStatus>{
      for (final application in applications)
        application.id: application.usesCardPayment
            ? (cardPaymentStatuses?[application.id] ??
                  application.paymentStatus)
            : application.paymentStatus,
    };
    bool hasOpenPayments() {
      return applications.any((application) {
        final paymentStatus =
            paymentStatuses[application.id] ??
            RidePassengerPaymentStatus.pending;
        if (application.requiresPaymentMethodSelection) {
          return true;
        }
        return paymentStatus == RidePassengerPaymentStatus.pending;
      });
    }

    final submitted = await showModalBottomSheet<_RideCompletionReviewResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final palette = context.palette;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.l,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 44,
                        child: Divider(thickness: 4, color: palette.border),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Rate your passengers',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      ride.acceptsCardPayments
                          ? 'When you finish the ride, every unresolved passenger payment will be locked. Approved card payments stay paid; anything still pending or without a selected method becomes unpaid automatically.'
                          : 'Before finishing the ride, rate each passenger. Any transfer still left pending when you finish will be marked unpaid automatically.',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.s),
                      decoration: BoxDecoration(
                        color: palette.input,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: palette.border),
                      ),
                      child: Text(
                        ride.acceptsCardPayments
                            ? hasOpenPayments()
                                  ? 'Some passengers are still unresolved. They will be marked unpaid when the ride finishes.'
                                  : 'All passengers already have a final payment status.'
                            : hasOpenPayments()
                            ? 'Any transfer you leave pending will become unpaid when the ride finishes.'
                            : 'All transfer payments already have a final status.',
                        style: TextStyle(
                          color: palette.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: applications.map((application) {
                            final rating = ratings[application.id] ?? 5;
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.s,
                              ),
                              child: _PassengerReviewTile(
                                name: application.passengerName,
                                subtitle: application.passengerEmail,
                                rating: rating,
                                paymentStatus:
                                    paymentStatuses[application.id] ??
                                    RidePassengerPaymentStatus.pending,
                                paymentLocked:
                                    application.usesCardPayment ||
                                    application.isPaymentLocked,
                                paymentMethodLabel:
                                    application.requiresPaymentMethodSelection
                                    ? 'Passenger has not selected a payment method yet'
                                    : application.paymentMethod.label,
                                onRatingChanged: (value) {
                                  setModalState(() {
                                    ratings[application.id] = value;
                                  });
                                },
                                onPaymentStatusChanged:
                                    application.usesManualTransfer &&
                                        !application.isPaymentLocked
                                    ? (value) {
                                        setModalState(() {
                                          paymentStatuses[application.id] =
                                              value;
                                        });
                                      }
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.primary,
                          foregroundColor: palette.primaryForeground,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(_RideCompletionReviewResult(paymentStatuses)),
                        child: const Text(
                          'Save payment statuses and finish ride',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Go Back'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return submitted;
  }

  Widget _passengerSection(
    BuildContext context,
    RidesEntity ride,
    List<RideApplicationEntity> applications,
  ) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passengers (${applications.length}/${ride.totalSeats})',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          if (applications.isEmpty)
            Text(
              'No passengers have applied yet.',
              style: TextStyle(color: palette.textSecondary),
            )
          else
            for (final application in applications) ...[
              _PassengerPaymentTile(
                ride: ride,
                application: application,
                initials: _initials(application.passengerName),
              ),
              if (application != applications.last)
                Divider(color: palette.border),
            ],
        ],
      ),
    );
  }

  Widget _errorCard(BuildContext context, String title, String message) {
    final palette = context.palette;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: palette.error, size: 40),
            const SizedBox(height: AppSpacing.s),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _rideStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Future<Map<String, RidePassengerPaymentStatus>> _loadCardPaymentStatuses(
    WidgetRef ref,
    RidesEntity ride,
    List<RideApplicationEntity> applications,
  ) async {
    final repository = ref.read(paymentRepositoryProvider);
    final statuses = <String, RidePassengerPaymentStatus>{};

    for (final application in applications) {
      try {
        if (!application.usesCardPayment) {
          statuses[application.id] = application.paymentStatus;
          continue;
        }
        final paymentRecord = await repository.getPaymentStatus(
          rideId: ride.id,
          passengerId: application.passengerId,
        );
        statuses[application.id] = _paymentStatusFromRecord(paymentRecord);
      } catch (_) {
        statuses[application.id] = RidePassengerPaymentStatus.pending;
      }
    }

    return statuses;
  }

  RidePassengerPaymentStatus _paymentStatusFromRecord(PaymentRecord? record) {
    final normalizedStatus = record?.effectiveStatus.trim().toLowerCase();
    if (normalizedStatus == 'approved') {
      return RidePassengerPaymentStatus.paid;
    }
    if (normalizedStatus == 'rejected' ||
        normalizedStatus == 'cancelled' ||
        normalizedStatus == 'expired') {
      return RidePassengerPaymentStatus.unpaid;
    }
    return RidePassengerPaymentStatus.pending;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || name.trim().isEmpty) {
      return 'P';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

class _PassengerPaymentTile extends ConsumerWidget {
  const _PassengerPaymentTile({
    required this.ride,
    required this.application,
    required this.initials,
  });

  final RidesEntity ride;
  final RideApplicationEntity application;
  final String initials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final paymentStatus = application.usesCardPayment
        ? _paymentStatusFromRecord(
            ref
                .watch(
                  paymentRecordStreamProvider(
                    PaymentRecordRequest(
                      rideId: ride.id,
                      passengerId: application.passengerId,
                    ),
                  ),
                )
                .valueOrNull,
          )
        : application.requiresPaymentMethodSelection
        ? application.isPaymentLocked
              ? application.paymentStatus
              : RidePassengerPaymentStatus.pending
        : application.paymentStatus;

    final paymentSummary = application.requiresPaymentMethodSelection
        ? application.isPaymentLocked
              ? 'No payment method was selected before the ride finished. This passenger was marked as unpaid.'
              : 'Passenger still needs to choose card or direct transfer.'
        : application.usesCardPayment
        ? paymentStatus == RidePassengerPaymentStatus.paid
              ? 'Card payment confirmed by Mercado Pago.'
              : paymentStatus == RidePassengerPaymentStatus.unpaid
              ? 'Card payment failed or was rejected.'
              : 'Waiting for card payment confirmation.'
        : 'Transfer status: ${paymentStatus.label}.';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: palette.primary,
        child: Text(
          initials,
          style: TextStyle(color: palette.primaryForeground),
        ),
      ),
      title: Text(application.passengerName),
      subtitle: Text(
        '${application.passengerEmail}\n${application.paymentMethod.label}\n$paymentSummary',
      ),
      isThreeLine: true,
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _paymentBadgeBackground(context, paymentStatus),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Text(
          paymentStatus.label,
          style: TextStyle(
            color: _paymentBadgeForeground(context, paymentStatus),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  RidePassengerPaymentStatus _paymentStatusFromRecord(PaymentRecord? record) {
    final normalizedStatus = record?.effectiveStatus.trim().toLowerCase();
    if (normalizedStatus == 'approved') {
      return RidePassengerPaymentStatus.paid;
    }
    if (normalizedStatus == 'rejected' ||
        normalizedStatus == 'cancelled' ||
        normalizedStatus == 'expired') {
      return RidePassengerPaymentStatus.unpaid;
    }
    return RidePassengerPaymentStatus.pending;
  }

  Color _paymentBadgeBackground(
    BuildContext context,
    RidePassengerPaymentStatus status,
  ) {
    final palette = context.palette;

    switch (status) {
      case RidePassengerPaymentStatus.paid:
        return palette.accentSoft;
      case RidePassengerPaymentStatus.unpaid:
        return palette.error.withValues(alpha: 0.16);
      case RidePassengerPaymentStatus.pending:
        return palette.warning.withValues(alpha: 0.16);
    }
  }

  Color _paymentBadgeForeground(
    BuildContext context,
    RidePassengerPaymentStatus status,
  ) {
    final palette = context.palette;

    switch (status) {
      case RidePassengerPaymentStatus.paid:
        return palette.accent;
      case RidePassengerPaymentStatus.unpaid:
        return palette.error;
      case RidePassengerPaymentStatus.pending:
        return palette.warning;
    }
  }
}

class _PassengerReviewTile extends StatelessWidget {
  const _PassengerReviewTile({
    required this.name,
    required this.subtitle,
    required this.rating,
    required this.paymentStatus,
    required this.paymentLocked,
    required this.paymentMethodLabel,
    required this.onRatingChanged,
    this.onPaymentStatusChanged,
  });

  final String name;
  final String subtitle;
  final int rating;
  final RidePassengerPaymentStatus paymentStatus;
  final bool paymentLocked;
  final String paymentMethodLabel;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<RidePassengerPaymentStatus>? onPaymentStatusChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            paymentMethodLabel,
            style: TextStyle(
              color: palette.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (paymentLocked)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: palette.input,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: palette.border),
              ),
              child: Text(
                paymentStatus == RidePassengerPaymentStatus.paid
                    ? 'Paid and locked'
                    : paymentStatus.label,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              children: [
                _PaymentDecisionButton(
                  label: 'Paid',
                  isSelected: paymentStatus == RidePassengerPaymentStatus.paid,
                  onTap: () => onPaymentStatusChanged?.call(
                    RidePassengerPaymentStatus.paid,
                  ),
                ),
                _PaymentDecisionButton(
                  label: 'Unpaid',
                  isSelected:
                      paymentStatus == RidePassengerPaymentStatus.unpaid,
                  onTap: () => onPaymentStatusChanged?.call(
                    RidePassengerPaymentStatus.unpaid,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: 4,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                onPressed: () => onRatingChanged(starValue),
                icon: Icon(
                  starValue <= rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: palette.warning,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PaymentDecisionButton extends StatelessWidget {
  const _PaymentDecisionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: palette.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: isSelected ? palette.primary : palette.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: isSelected ? palette.primary : palette.border,
      ),
      backgroundColor: palette.card,
    );
  }
}

class _RideCompletionReviewResult {
  const _RideCompletionReviewResult(this.paymentStatuses);

  final Map<String, RidePassengerPaymentStatus> paymentStatuses;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: palette.secondary),
        const SizedBox(width: AppSpacing.s),
        Text(
          '$label: ',
          style: TextStyle(
            color: palette.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyActiveRide extends StatelessWidget {
  const _EmptyActiveRide({required this.onCreateRide});

  final VoidCallback onCreateRide;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.m),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 56,
              color: palette.primary,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'You do not have an active ride right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            ElevatedButton(
              onPressed: onCreateRide,
              child: const Text('Create a ride'),
            ),
          ],
        ),
      ),
    );
  }
}
