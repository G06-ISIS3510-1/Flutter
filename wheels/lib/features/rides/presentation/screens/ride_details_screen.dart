import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/domain/entities/auth_entity.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/utils/app_formatter.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../data/models/local_ride_details_cache_model.dart';
import '../../domain/entities/rides_entity.dart';
import '../models/ride_listing.dart';
import '../providers/rides_providers.dart';

class RideDetailsScreen extends ConsumerStatefulWidget {
  const RideDetailsScreen({required this.rideId, super.key});

  final String rideId;

  @override
  ConsumerState<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends ConsumerState<RideDetailsScreen> {
  LocalRideDetailsCacheModel? _cachedRideDetails;
  bool _hasLoadedCachedRide = false;
  bool _isUsingCachedFallback = false;
  String? _lastSavedRideSignature;

  @override
  void initState() {
    super.initState();
    _loadCachedRideDetails();
  }

  @override
  void didUpdateWidget(covariant RideDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rideId == widget.rideId) {
      return;
    }

    setState(() {
      _cachedRideDetails = null;
      _hasLoadedCachedRide = false;
      _isUsingCachedFallback = false;
      _lastSavedRideSignature = null;
    });
    _loadCachedRideDetails();
  }

  Future<void> _loadCachedRideDetails() async {
    final localDataSource = ref.read(rideDetailsLocalDataSourceProvider);
    final cache = await localDataSource.loadLatestRideDetails();
    if (!mounted) {
      return;
    }

    if (cache == null) {
      setState(() {
        _hasLoadedCachedRide = true;
      });
      return;
    }

    if (!cache.matchesRide(widget.rideId) || cache.isExpired()) {
      await localDataSource.clearLatestRideDetails();
      if (!mounted) {
        return;
      }
      setState(() {
        _cachedRideDetails = null;
        _hasLoadedCachedRide = true;
        _isUsingCachedFallback = false;
        _lastSavedRideSignature = null;
      });
      return;
    }

    setState(() {
      _cachedRideDetails = cache;
      _hasLoadedCachedRide = true;
      _isUsingCachedFallback = false;
      _lastSavedRideSignature = _rideSignature(cache.toEntity());
    });
  }

  Future<void> _saveCachedRideDetails(RidesEntity ride) async {
    final cache = LocalRideDetailsCacheModel.create(ride: ride);
    final nextSignature = _rideSignature(ride);
    if (_lastSavedRideSignature == nextSignature) {
      return;
    }

    await ref
        .read(rideDetailsLocalDataSourceProvider)
        .saveLatestRideDetails(cache);

    if (!mounted) {
      return;
    }

    setState(() {
      _cachedRideDetails = cache;
      _isUsingCachedFallback = false;
      _lastSavedRideSignature = nextSignature;
    });
  }

  Future<void> _clearCachedRideDetails() async {
    await ref.read(rideDetailsLocalDataSourceProvider).clearLatestRideDetails();
    if (!mounted) {
      return;
    }

    setState(() {
      _cachedRideDetails = null;
      _isUsingCachedFallback = false;
      _lastSavedRideSignature = null;
    });
  }

  String _rideSignature(RidesEntity ride) {
    return [
      ride.id,
      ride.updatedAt.toIso8601String(),
      ride.availableSeats.toString(),
      ride.status,
      ride.passengerIds.join('|'),
    ].join('::');
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    final rideAsync = ref.watch(rideProvider(widget.rideId));
    final applicationAsync = ref.watch(
      passengerRideApplicationProvider(widget.rideId),
    );
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final isOnline = connectivityAsync.valueOrNull ?? true;
    final applyState = ref.watch(rideApplicationControllerProvider);
    final currentUser = ref.watch(authUserProvider);
    final palette = context.palette;
    final cachedRide = _cachedRideDetails?.toEntity();

    ref.listen<AsyncValue<RidesEntity?>>(rideProvider(widget.rideId), (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (ride) async {
          if (ride == null) {
            await _clearCachedRideDetails();
            return;
          }
          await _saveCachedRideDetails(ride);
        },
        error: (_, _) {
          if (!mounted || cachedRide == null) {
            return;
          }
          setState(() {
            _isUsingCachedFallback = true;
          });
        },
      );
    });

    ref.listen<AsyncValue<void>>(rideApplicationControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (_) {
          if ((previous?.isLoading ?? false) && mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Your seat request was sent successfully.'),
                ),
              );
          }
        },
        error: (error, _) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(error.toString().replaceFirst('Exception: ', '')),
              ),
            );
        },
      );
    });

    ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
      next.whenData((hasConnection) {
        if (!mounted) {
          return;
        }

        final previousConnection = previous?.valueOrNull;
        if (previousConnection == hasConnection) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                hasConnection
                    ? 'Connection restored. Ride actions are available again.'
                    : 'You are offline. Joining a ride and payment actions are temporarily unavailable.',
              ),
            ),
          );
      });
    });

    return AppScaffold(
      title: 'Ride Details',
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.home,
        role: role,
      ),
      child: rideAsync.when(
        data: (ride) {
          if (ride == null) {
            return const Center(child: Text('Ride not found'));
          }

          return _buildRideContent(
            ride: ride,
            palette: palette,
            currentUser: currentUser,
            applicationAsync: applicationAsync,
            applyState: applyState,
            isOnline: isOnline,
          );
        },
        loading: () {
          if (!_hasLoadedCachedRide) {
            return const Center(child: CircularProgressIndicator());
          }
          if (cachedRide == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildRideContent(
            ride: cachedRide,
            palette: palette,
            currentUser: currentUser,
            applicationAsync: applicationAsync,
            applyState: applyState,
            isOnline: isOnline,
            showCachedNotice: true,
            cachedNoticeTitle: 'Showing saved ride details',
            cachedNoticeMessage:
                'We loaded the latest saved ride while refreshing live availability.',
          );
        },
        error: (error, _) {
          if (cachedRide != null) {
            return _buildRideContent(
              ride: cachedRide,
              palette: palette,
              currentUser: currentUser,
              applicationAsync: applicationAsync,
              applyState: applyState,
              isOnline: isOnline,
              showCachedNotice: true,
              cachedNoticeTitle: 'Offline fallback in use',
              cachedNoticeMessage:
                  'Live ride data is unavailable right now. You are seeing the latest saved version.',
            );
          }

          return Center(
            child: Text(error.toString(), textAlign: TextAlign.center),
          );
        },
      ),
    );
  }

  Widget _buildRideContent({
    required RidesEntity ride,
    required AppThemePalette palette,
    required AuthEntity? currentUser,
    required AsyncValue<RideApplicationEntity?> applicationAsync,
    required AsyncValue<void> applyState,
    required bool isOnline,
    bool showCachedNotice = false,
    String? cachedNoticeTitle,
    String? cachedNoticeMessage,
  }) {
    final passengerApplication = applicationAsync.valueOrNull;
    final isOwnRide = currentUser?.uid == ride.driverId;
    final hasApplied = passengerApplication != null;
    final requiresLiveBackendState = !showCachedNotice && isOnline;
    final canApply =
        requiresLiveBackendState &&
        !isOwnRide &&
        ride.isOpen &&
        ride.hasAvailableSeats &&
        !hasApplied &&
        currentUser != null &&
        !showCachedNotice;
    final canOpenPayment =
        requiresLiveBackendState && hasApplied && !isOwnRide;
    final actionBlockedReason = _criticalActionBlockedReason(
      isOnline: isOnline,
      showCachedNotice: showCachedNotice,
      isOwnRide: isOwnRide,
      currentUser: currentUser,
      hasApplied: hasApplied,
      ride: ride,
    );

    return ListView(
      children: [
        if (showCachedNotice) ...[
          _cachedRideNotice(
            title: cachedNoticeTitle ?? 'Saved ride details',
            message: cachedNoticeMessage ?? 'You are seeing locally saved data.',
          ),
          const SizedBox(height: AppSpacing.m),
        ],
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: palette.primary,
                    child: Text(
                      ride.driverInitials,
                      style: TextStyle(color: palette.primaryForeground),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      ride.driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    ride.priceLabel,
                    style: TextStyle(
                      color: palette.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              _DetailRow(Icons.trip_origin, 'Origin', ride.origin),
              const SizedBox(height: AppSpacing.s),
              _DetailRow(Icons.place_outlined, 'Destination', ride.destination),
              const SizedBox(height: AppSpacing.s),
              _DetailRow(Icons.calendar_month_outlined, 'Date', ride.dateLabel),
              const SizedBox(height: AppSpacing.s),
              _DetailRow(Icons.schedule_outlined, 'Departure', ride.departureLabel),
              const SizedBox(height: AppSpacing.s),
              _DetailRow(Icons.timer_outlined, 'Duration', ride.durationLabel),
              const SizedBox(height: AppSpacing.s),
              _DetailRow(
                Icons.event_seat_outlined,
                'Seats left',
                '${ride.availableSeats} of ${ride.totalSeats}',
              ),
              const SizedBox(height: AppSpacing.s),
              _DetailRow(
                ride.acceptsCardPayments
                    ? Icons.credit_card_outlined
                    : Icons.account_balance_outlined,
                'Payment',
                ride.paymentOptionLabel,
              ),
              const SizedBox(height: AppSpacing.s),
              _DetailRow(Icons.info_outline, 'Status', _statusLabel(ride.status)),
              if (ride.notes.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                _DetailRow(Icons.notes_outlined, 'Notes', ride.notes),
              ],
            ],
          ),
        ),
        if (ride.acceptsCardPayments) ...[
          const SizedBox(height: AppSpacing.m),
          _CardPayoutEstimateCard(ride: ride),
        ],
        const SizedBox(height: AppSpacing.m),
        if (isOwnRide)
          _messageCard(
            'This is your ride',
            'Passengers can already see it in the search list and apply from there.',
          )
        else if (hasApplied)
          _messageCard(
            'Application sent',
            'You already applied to this ride. We will keep this seat linked to your account.',
          )
        else if (!ride.hasAvailableSeats)
          _messageCard(
            'Ride is full',
            'All seats have already been taken for this trip.',
          )
        else if (!ride.isOpen)
          _messageCard(
            'Ride unavailable',
            'This ride is no longer open for new passengers.',
          ),
        if (actionBlockedReason != null) ...[
          const SizedBox(height: AppSpacing.s),
          _actionUnavailableNotice(actionBlockedReason),
        ],
        const SizedBox(height: AppSpacing.s),
        ElevatedButton(
          onPressed: canApply && !applyState.isLoading
              ? () async {
                  await ref
                      .read(rideApplicationControllerProvider.notifier)
                      .applyToRide(
                        rideId: ride.id,
                        passengerId: currentUser.uid,
                        passengerName: currentUser.fullName,
                        passengerEmail: currentUser.email,
                      );
                }
              : canOpenPayment && !showCachedNotice
              ? () => context.go(AppRoutes.paymentByRideId(ride.id))
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.accent,
            foregroundColor: palette.accentForeground,
            disabledBackgroundColor: palette.surfaceMuted,
            disabledForegroundColor: palette.textSecondary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: Text(
            _actionLabel(
              isOwnRide: isOwnRide,
              hasApplied: hasApplied,
              passengerApplication: passengerApplication,
              paymentOption: ride.paymentOption,
              rideStatus: ride.status,
              hasAvailableSeats: ride.hasAvailableSeats,
              isLoading: applyState.isLoading,
              isOnline: isOnline,
              showCachedNotice: showCachedNotice,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cachedRideNotice({
    required String title,
    required String message,
  }) {
    final palette = context.palette;
    final savedAtLabel = _cachedRideDetails == null
        ? null
        : 'Saved ${_formatSavedAt(_cachedRideDetails!.savedAt)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: palette.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isUsingCachedFallback
                ? Icons.cloud_off_outlined
                : Icons.offline_bolt_outlined,
            color: palette.secondary,
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                if (savedAtLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    savedAtLabel,
                    style: TextStyle(color: palette.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSavedAt(DateTime savedAt) {
    final local = savedAt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return 'on $day/$month/$year at $hour:$minute';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _actionLabel({
    required bool isOwnRide,
    required bool hasApplied,
    required RideApplicationEntity? passengerApplication,
    required RidePaymentOption paymentOption,
    required String rideStatus,
    required bool hasAvailableSeats,
    required bool isLoading,
    required bool isOnline,
    required bool showCachedNotice,
  }) {
    if (isLoading) {
      return 'Sending request...';
    }
    if (!isOnline) {
      return 'Reconnect to continue';
    }
    if (showCachedNotice) {
      return 'Waiting for live ride details';
    }
    if (isOwnRide) {
      return 'This is your ride';
    }
    if (hasApplied) {
      final paymentMethod =
          passengerApplication?.paymentMethod ??
          RidePassengerPaymentMethod.pendingSelection;
      if (paymentOption == RidePaymentOption.card &&
          paymentMethod == RidePassengerPaymentMethod.pendingSelection) {
        return 'Choose payment method';
      }
      return 'View payment status';
    }
    if (!hasAvailableSeats) {
      return 'Ride full';
    }
    if (rideStatus != 'open') {
      return 'Ride unavailable';
    }
    return 'Apply to this ride';
  }

  String? _criticalActionBlockedReason({
    required bool isOnline,
    required bool showCachedNotice,
    required bool isOwnRide,
    required AuthEntity? currentUser,
    required bool hasApplied,
    required RidesEntity ride,
  }) {
    if (isOwnRide || currentUser == null) {
      return null;
    }

    final mightApply = !hasApplied && ride.isOpen && ride.hasAvailableSeats;
    final mightContinueToPayment = hasApplied;
    if (!mightApply && !mightContinueToPayment) {
      return null;
    }

    if (!isOnline) {
      return mightContinueToPayment
          ? 'Reconnect to confirm the latest backend payment status before continuing.'
          : 'Reconnect to validate live seat availability before sending your request.';
    }

    if (showCachedNotice) {
      return mightContinueToPayment
          ? 'These details are cached. Payment-related actions stay blocked until live ride data is refreshed.'
          : 'These details are cached. Applying stays blocked until live availability is refreshed.';
    }

    return null;
  }

  Widget _messageCard(String title, String message) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: TextStyle(color: palette.textSecondary)),
        ],
      ),
    );
  }

  Widget _actionUnavailableNotice(String message) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: palette.warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_outlined, color: palette.warning),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live validation required',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: TextStyle(
                    color: palette.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPayoutEstimateCard extends StatelessWidget {
  const _CardPayoutEstimateCard({required this.ride});

  final RidesEntity ride;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final grossPerSeat = ride.pricePerSeat.toDouble();
    final feePerSeat = AppFormatter.mercadoPagoCardFee(grossPerSeat);
    final netPerSeat = AppFormatter.mercadoPagoCardNet(grossPerSeat);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card payment estimate',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'If a passenger pays in-app by card, the driver keeps about ${AppFormatter.cop(netPerSeat)} per seat.',
            style: TextStyle(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.m),
          _EstimateRow(label: 'Seat price', value: AppFormatter.cop(grossPerSeat)),
          const SizedBox(height: AppSpacing.s),
          _EstimateRow(
            label: 'Estimated Mercado Pago fee',
            value: AppFormatter.cop(feePerSeat),
          ),
          const SizedBox(height: AppSpacing.s),
          _EstimateRow(
            label: 'Driver receives',
            value: AppFormatter.cop(netPerSeat),
            emphasize: true,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Direct transfers still keep the full seat price.',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
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

class _EstimateRow extends StatelessWidget {
  const _EstimateRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? palette.primary : palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
