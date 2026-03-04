import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/rides_providers.dart';

class RidesSearchScreen extends ConsumerWidget {
  const RidesSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = ref.watch(activeRideCountProvider);

    return AppScaffold(
      title: 'Rides',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rides Search Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text('Active rides: $activeCount'),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Open Active Ride',
            onPressed: () => context.go(AppRoutes.activeRide),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Open Group Ride',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.groupByRideId('ride-123')),
          ),
        ],
      ),
    );
  }
}
