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

class ActiveRideScreen extends ConsumerWidget {
  const ActiveRideScreen({this.rideId, super.key});

  final String? rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideAsync = rideId == null
        ? ref.watch(currentDriverRideProvider)
        : ref.watch(rideProvider(rideId!));

    ref.listen<AsyncValue<void>>(rideStatusControllerProvider, (previous, next) {
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
      backgroundColor: AppColors.muted,
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

          final applicationsAsync = ref.watch(rideApplicationsProvider(ride.id));
          final statusState = ref.watch(rideStatusControllerProvider);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              _headerCard(ride),
              const SizedBox(height: AppSpacing.m),
              _routeCard(ride),
              const SizedBox(height: AppSpacing.m),
              _statusActions(
                context: context,
                ref: ref,
                rideId: ride.id,
                currentStatus: ride.status,
                isLoading: statusState.isLoading,
              ),
              const SizedBox(height: AppSpacing.m),
              applicationsAsync.when(
                data: (applications) => _passengerSection(ride, applications),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _errorCard(
                  'We could not load passenger applications.',
                  error.toString(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _errorCard(
          'We could not load your current ride.',
          error.toString(),
        ),
      ),
    );
  }

  Widget _headerCard(RidesEntity ride) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A5C), Color(0xFF2D5A8E)],
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
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              ride.driverInitials,
              style: const TextStyle(
                color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${ride.availableSeats}/${ride.totalSeats} seats available',
                  style: const TextStyle(color: Colors.white70),
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
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Text(
              _rideStatusLabel(ride.status),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(RidesEntity ride) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ride details',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
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
          if (ride.notes.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            _InfoRow(Icons.notes_outlined, 'Notes', ride.notes),
          ],
        ],
      ),
    );
  }

  Widget _statusActions({
    required BuildContext context,
    required WidgetRef ref,
    required String rideId,
    required String currentStatus,
    required bool isLoading,
  }) {
    Future<void> updateStatus(String status, String successMessage) async {
      await ref
          .read(rideStatusControllerProvider.notifier)
          .updateRideStatus(rideId: rideId, status: status);
      if (!context.mounted) {
        return;
      }
      ref.read(rideStatusControllerProvider.notifier).clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));

      if (status == 'cancelled' || status == 'completed') {
        context.go(AppRoutes.dashboard);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentStatus == 'open')
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () => updateStatus('in_progress', 'Ride started successfully.'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.accentForeground,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(isLoading ? 'Updating...' : 'Start ride'),
          ),
        if (currentStatus == 'in_progress')
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () => updateStatus('completed', 'Ride finished successfully.'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(isLoading ? 'Updating...' : 'Finish ride'),
          ),
        const SizedBox(height: AppSpacing.s),
        OutlinedButton(
          onPressed: isLoading || currentStatus == 'completed'
              ? null
              : () => updateStatus('cancelled', 'Ride cancelled.'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: const Text('Cancel ride'),
        ),
      ],
    );
  }

  Widget _passengerSection(
    RidesEntity ride,
    List<RideApplicationEntity> applications,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passengers (${applications.length}/${ride.totalSeats})',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          if (applications.isEmpty)
            const Text(
              'No passengers have applied yet.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            for (final application in applications) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _initials(application.passengerName),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(application.passengerName),
                subtitle: Text(application.passengerEmail),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    application.status,
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (application != applications.last)
                const Divider(color: AppColors.border),
            ],
        ],
      ),
    );
  }

  Widget _errorCard(String title, String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.s),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
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
        return 'In progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
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

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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

class _EmptyActiveRide extends StatelessWidget {
  const _EmptyActiveRide({required this.onCreateRide});

  final VoidCallback onCreateRide;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.m),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_outlined, size: 56),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'You do not have an active ride right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.foreground,
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
