import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
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
  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    final rideAsync = ref.watch(rideProvider(widget.rideId));
    final applicationAsync = ref.watch(
      passengerRideApplicationProvider(widget.rideId),
    );
    final applyState = ref.watch(rideApplicationControllerProvider);
    final currentUser = ref.watch(authUserProvider);

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

          final isOwnRide = currentUser?.uid == ride.driverId;
          final hasApplied = applicationAsync.valueOrNull != null;
          final canApply =
              !isOwnRide &&
              ride.isOpen &&
              ride.hasAvailableSeats &&
              !hasApplied &&
              currentUser != null;
          final canOpenPayment = hasApplied && !isOwnRide;

          return ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: AppShadows.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            ride.driverInitials,
                            style: const TextStyle(
                              color: AppColors.primaryForeground,
                            ),
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
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _DetailRow(Icons.trip_origin, 'Origin', ride.origin),
                    const SizedBox(height: AppSpacing.s),
                    _DetailRow(
                      Icons.place_outlined,
                      'Destination',
                      ride.destination,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    _DetailRow(
                      Icons.calendar_month_outlined,
                      'Date',
                      ride.dateLabel,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    _DetailRow(
                      Icons.schedule_outlined,
                      'Departure',
                      ride.departureLabel,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    _DetailRow(
                      Icons.timer_outlined,
                      'Duration',
                      ride.durationLabel,
                    ),
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
                    _DetailRow(
                      Icons.info_outline,
                      'Status',
                      _statusLabel(ride.status),
                    ),
                    if (ride.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s),
                      _DetailRow(Icons.notes_outlined, 'Notes', ride.notes),
                    ],
                  ],
                ),
              ),
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
                    : canOpenPayment
                    ? () => context.go(AppRoutes.paymentByRideId(ride.id))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentForeground,
                  disabledBackgroundColor: AppColors.muted,
                  disabledForegroundColor: AppColors.mutedForeground,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: Text(
                  _actionLabel(
                    isOwnRide: isOwnRide,
                    hasApplied: hasApplied,
                    paymentOption: ride.paymentOption,
                    rideStatus: ride.status,
                    hasAvailableSeats: ride.hasAvailableSeats,
                    isLoading: applyState.isLoading,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(error.toString(), textAlign: TextAlign.center)),
      ),
    );
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
    required RidePaymentOption paymentOption,
    required String rideStatus,
    required bool hasAvailableSeats,
    required bool isLoading,
  }) {
    if (isLoading) {
      return 'Sending request...';
    }
    if (isOwnRide) {
      return 'This is your ride';
    }
    if (hasApplied) {
      return paymentOption == RidePaymentOption.card
          ? 'Choose payment method'
          : 'View payment instructions';
    }
    if (!hasAvailableSeats) {
      return 'Ride full';
    }
    if (rideStatus != 'open') {
      return 'Ride unavailable';
    }
    return 'Apply to this ride';
  }

  Widget _messageCard(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
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
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.s),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
