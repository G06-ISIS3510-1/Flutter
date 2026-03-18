import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/reviews_providers.dart';
import '../widgets/review_widgets.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final reviewsView = ref.watch(reviewsViewDataProvider);
    final selectedFilter = ref.watch(selectedReviewFilterProvider);
    final filteredReviews = ref.watch(filteredReviewsProvider);

    return AppScaffold(
      title: 'Reviews',
      showAppBar: false,
      backgroundColor: const Color(0xFFF3F6FB),
      maxScrollableWidth: 440,
      scrollableHeader: _ReviewsHeader(
        userName: reviewsView.user.fullName,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.profile);
          }
        },
      ),
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.profile,
        role: role,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          0,
          AppSpacing.m,
          AppSpacing.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: const Offset(0, -36),
              child: UserReviewSummaryCard(user: reviewsView.user),
            ),
            RatingBreakdownCard(
              breakdown: reviewsView.breakdown,
              totalReviews: reviewsView.user.totalReviews,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Filter Reviews'),
            const SizedBox(height: AppSpacing.m),
            ReviewFilterChips(
              selectedFilter: selectedFilter,
              onSelected: (filter) {
                ref.read(selectedReviewFilterProvider.notifier).state = filter;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Recent Feedback'),
            const SizedBox(height: AppSpacing.m),
            if (filteredReviews.isEmpty)
              ReviewsEmptyState(filter: selectedFilter)
            else
              Column(
                children: [
                  for (final review in filteredReviews) ...[
                    ReviewCard(review: review),
                    if (review != filteredReviews.last)
                      const SizedBox(height: AppSpacing.m),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsHeader extends StatelessWidget {
  const _ReviewsHeader({required this.userName, required this.onBack});

  final String userName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryForeground,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            ),
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            label: const Text(
              'Back',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          const Text(
            'Reviews',
            style: TextStyle(
              color: AppColors.primaryForeground,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'What other users say about $userName',
            style: const TextStyle(
              color: Color(0xFFE2ECF8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF59749B),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
