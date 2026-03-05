import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/rides_providers.dart';

class ActiveRideScreen extends ConsumerWidget {
  const ActiveRideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(ridesStatusProvider);
    final publishedSummary = ref.watch(publishedRideSummaryProvider);
    final role = ref.watch(currentUserRoleProvider);

    return AppScaffold(
      title: 'Active Ride',
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.middle,
        role: role,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Ride Screen',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(status, style: const TextStyle(color: AppColors.textSecondary)),
          if (publishedSummary != null) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              'Published ride: $publishedSummary',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
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
