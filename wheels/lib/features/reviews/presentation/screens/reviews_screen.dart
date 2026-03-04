import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/reviews_providers.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewSummary = ref.watch(reviewsSummaryProvider);

    return AppScaffold(
      title: 'Reviews',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reviews Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text(reviewSummary),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Back to Profile',
            onPressed: () => context.go(AppRoutes.profile),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Open Dashboard',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ],
      ),
    );
  }
}
