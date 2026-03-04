import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/rides_providers.dart';

class CreateRideScreen extends ConsumerWidget {
  const CreateRideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(ridesStatusProvider);

    return AppScaffold(
      title: 'Create Ride',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Ride Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text(status),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Find Rides',
            onPressed: () => context.go(AppRoutes.rides),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Go to Payment',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.payment),
          ),
        ],
      ),
    );
  }
}
