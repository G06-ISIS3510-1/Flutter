import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/trust_providers.dart';

class TrustScreen extends ConsumerWidget {
  const TrustScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustState = ref.watch(trustStatusProvider);

    return AppScaffold(
      title: 'Trust',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trust Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text(trustState),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Back to Profile',
            onPressed: () => context.go(AppRoutes.profile),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Go to Dashboard',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ],
      ),
    );
  }
}
