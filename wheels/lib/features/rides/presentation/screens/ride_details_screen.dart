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
import '../mock/rides_mock_data.dart';

class RideDetailsScreen extends ConsumerWidget {
  const RideDetailsScreen({required this.rideId, super.key});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final ride = findRideById(rideId, DateTime.now());

    if (ride == null) {
      return AppScaffold(
        title: 'Ride Details',
        bottomNavigationBar: AppBottomNav(
          currentTab: AppBottomNavTab.home,
          role: role,
        ),
        child: const Center(child: Text('Ride not found')),
      );
    }

    return AppScaffold(
      title: 'Ride Details',
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.home,
        role: role,
      ),
      child: ListView(
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
                  '${ride.seatsLeft}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.groupByRideId(ride.id)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.accentForeground,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: const Text('Request Ride'),
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
