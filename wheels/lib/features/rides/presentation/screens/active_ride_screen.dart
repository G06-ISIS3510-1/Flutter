import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/rides_providers.dart';

class ActiveRideScreen extends ConsumerWidget {
  const ActiveRideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(ridesStatusProvider);

    return AppScaffold(
      title: 'Active Ride',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Ride Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text(status),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Go to Notifications',
            onPressed: () => context.go(AppRoutes.notifications),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Back to Dashboard',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ],
      ),
    );
  }
}
