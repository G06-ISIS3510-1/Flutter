import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../providers/reviews_providers.dart';
import '../widgets/review_widgets.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final role = ref.watch(currentUserRoleProvider);
    final reviewsState = ref.watch(reviewsViewDataProvider);
    final reviewsLoadState = reviewsState.valueOrNull;
    final reviewsView = reviewsLoadState?.viewData;
    final selectedFilter = ref.watch(selectedReviewFilterProvider);
    final filteredReviews = ref.watch(filteredReviewsProvider);

    return AppScaffold(
      title: 'Reviews',
      showAppBar: false,
      backgroundColor: palette.background,
      maxScrollableWidth: 440,
      scrollableHeader: _ReviewsHeader(
        userName: reviewsView?.user.fullName ?? 'your profile',
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
            if (reviewsView == null)
              reviewsState.when(
                data: (_) => const SizedBox.shrink(),
                loading: () => const _ReviewsLoadingState(),
                error: (error, _) => _ReviewsLoadError(
                  error: error,
                  onRetry: () {
                    ref.read(reviewsViewDataProvider.notifier).refresh();
                  },
                ),
              )
            else ...[
              Transform.translate(
                offset: const Offset(0, -22),
                child: UserReviewSummaryCard(user: reviewsView.user),
              ),
              if (reviewsLoadState?.isFromCache ?? false) ...[
                _CacheNotice(loadState: reviewsLoadState!),
                const SizedBox(height: AppSpacing.m),
              ],
              RatingBreakdownCard(
                breakdown: reviewsView.breakdown,
                totalReviews: reviewsView.user.totalReviews,
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(label: 'Filter Reviews'),
              const SizedBox(height: AppSpacing.m),
              ReviewFilterChips(
                selectedFilter: selectedFilter,
                onSelected: (filter) {
                  ref.read(selectedReviewFilterProvider.notifier).state =
                      filter;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  const Expanded(
                    child: _SectionTitle(label: 'Recent Feedback'),
                  ),
                  IconButton(
                    tooltip: 'Refresh reviews',
                    onPressed: () {
                      ref.read(reviewsViewDataProvider.notifier).refresh();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
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
          ],
        ),
      ),
    );
  }
}

class _CacheNotice extends StatelessWidget {
  const _CacheNotice({required this.loadState});

  final ReviewsLoadState loadState;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final savedAt = loadState.savedAt;
    final detail = savedAt == null
        ? 'Showing saved reviews.'
        : 'Saved ${_formatCacheSavedAt(savedAt)}.';
    final message = loadState.isOffline
        ? '$detail You are offline, so cached reviews are being shown.'
        : loadState.hasRemoteError
        ? '$detail Could not reach the server, so these reviews may be outdated.'
        : loadState.isStaleCache
        ? '$detail Updating from the server...'
        : '$detail Loaded from cache.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storage_rounded, color: palette.accent, size: 20),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCacheSavedAt(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day} at $hour:$minute';
  }
}

class _ReviewsLoadingState extends StatelessWidget {
  const _ReviewsLoadingState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.l),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: palette.accent),
          const SizedBox(height: AppSpacing.m),
          Text(
            'Loading reviews...',
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsLoadError extends StatelessWidget {
  const _ReviewsLoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isOffline = error is ReviewsOfflineException;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.l),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: palette.accent, size: 34),
          const SizedBox(height: AppSpacing.m),
          Text(
            isOffline
                ? 'Connect to the internet to load reviews.'
                : 'Reviews are not available right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            isOffline
                ? 'There are no cached reviews on this device yet. Once they load successfully, they will be available from cache if the connection drops later.'
                : 'Try again in a moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
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
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 54),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primary, palette.primaryLight],
        ),
        borderRadius: const BorderRadius.only(
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
              foregroundColor: palette.primaryForeground,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            ),
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            label: const Text(
              'Back',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'Reviews',
            style: TextStyle(
              color: palette.primaryForeground,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'What other users say about $userName',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.primaryForeground.withValues(alpha: 0.82),
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Text(
      label,
      style: TextStyle(
        color: palette.textSecondary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
