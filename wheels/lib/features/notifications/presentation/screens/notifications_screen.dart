import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(notificationsMessageProvider);
    final role = ref.watch(currentUserRoleProvider);

    return AppScaffold(
      title: 'Notifications',
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.alerts,
        role: role,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications Screen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(notice),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Go to Dashboard',
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Open Active Ride',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.activeRide),
          ),
        ],
      ),
    );
  }
}
