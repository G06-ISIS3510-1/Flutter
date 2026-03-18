import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/reviews_providers.dart';

class UserReviewSummaryCard extends StatelessWidget {
  const UserReviewSummaryCard({required this.user, super.key});

  final ReviewedUserData user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(34),
        boxShadow: AppShadows.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(initials: user.initials),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.accent,
                          size: 21,
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          user.badgeLabel,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.memberSince,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _StarRow(rating: 5, starSize: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${user.totalReviews} reviews',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.supportingText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RatingBreakdownCard extends StatelessWidget {
  const RatingBreakdownCard({
    required this.breakdown,
    required this.totalReviews,
    super.key,
  });

  final List<ReviewBreakdownItemData> breakdown;
  final int totalReviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Breakdown',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          const Text(
            'A quick look at how this rating is built',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          for (final item in breakdown) ...[
            _BreakdownRow(item: item, totalReviews: totalReviews),
            if (item != breakdown.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class ReviewFilterChips extends StatelessWidget {
  const ReviewFilterChips({
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });

  final ReviewFilter selectedFilter;
  final ValueChanged<ReviewFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ReviewFilter.values.map((filter) {
        final isSelected = filter == selectedFilter;

        return ChoiceChip(
          selected: isSelected,
          label: Text(_filterLabel(filter)),
          onSelected: (_) => onSelected(filter),
          backgroundColor: AppColors.card,
          selectedColor: const Color(0xFFEAFBF4),
          side: BorderSide(
            color: isSelected ? const Color(0xFFBDEED9) : AppColors.border,
          ),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.accentHover : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }).toList(),
    );
  }

  static String _filterLabel(ReviewFilter filter) {
    return switch (filter) {
      ReviewFilter.all => 'All',
      ReviewFilter.asDriver => 'As Driver',
      ReviewFilter.asPassenger => 'As Passenger',
      ReviewFilter.recent => 'Recent',
    };
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, super.key});

  final ReviewItemData review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFEAF2FD),
                child: Text(
                  review.reviewerInitials,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StarRow(rating: review.rating),
                        const SizedBox(width: AppSpacing.s),
                        _RoleTag(roleTag: review.roleTag),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                review.dateLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            review.reviewText,
            style: const TextStyle(
              color: Color(0xFF526A8E),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewsEmptyState extends StatelessWidget {
  const ReviewsEmptyState({required this.filter, super.key});

  final ReviewFilter filter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFEAFBF4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          const Text(
            'No reviews here yet',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'There are no reviews available for ${_filterDescription(filter)} right now.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static String _filterDescription(ReviewFilter filter) {
    return switch (filter) {
      ReviewFilter.all => 'this section',
      ReviewFilter.asDriver => 'the driver role',
      ReviewFilter.asPassenger => 'the passenger role',
      ReviewFilter.recent => 'recent activity',
    };
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 94,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5E8BC7), AppColors.primary],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primaryForeground,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item, required this.totalReviews});

  final ReviewBreakdownItemData item;
  final int totalReviews;

  @override
  Widget build(BuildContext context) {
    final progress = totalReviews == 0 ? 0.0 : item.count / totalReviews;

    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Row(
            children: [
              Text(
                '${item.stars}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFF6B547),
                size: 18,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE7ECF5),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF63D7AB)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        SizedBox(
          width: 22,
          child: Text(
            '${item.count}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, this.starSize = 16});

  final int rating;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: const Color(0xFFF6B547),
          size: starSize,
        );
      }),
    );
  }
}

class _RoleTag extends StatelessWidget {
  const _RoleTag({required this.roleTag});

  final ReviewRoleTag roleTag;

  @override
  Widget build(BuildContext context) {
    final isDriver = roleTag == ReviewRoleTag.driver;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDriver ? const Color(0xFFEAF2FD) : const Color(0xFFEAFBF4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isDriver ? 'As Driver' : 'As Passenger',
        style: TextStyle(
          color: isDriver ? AppColors.secondary : AppColors.accentHover,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
