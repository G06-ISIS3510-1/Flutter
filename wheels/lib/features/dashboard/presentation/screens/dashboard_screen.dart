import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);

    return AppScaffold(
      title: 'Dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text(summary),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Create Ride',
            onPressed: () => context.go(AppRoutes.createRide),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Notifications',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.notifications),
          ),
        ],
      ),
    );
  }
}
