import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(profileSummaryProvider);

    return AppScaffold(
      title: 'Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text(summary),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Go to Trust',
            onPressed: () => context.go(AppRoutes.trust),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Go to Reviews',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.reviews),
          ),
        ],
      ),
    );
  }
}
