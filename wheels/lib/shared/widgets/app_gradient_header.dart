import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme_palette.dart';

class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({
    required this.title,
    required this.subtitle,
    this.backLabel = 'Back',
    this.onBack,
    this.height = 180,
    super.key,
  });

  final String title;
  final String subtitle;
  final String backLabel;
  final VoidCallback? onBack;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.l,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.primary, palette.primaryLight],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.md),
          bottomRight: Radius.circular(AppRadius.md),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.primaryForeground,
              size: 20,
            ),
            label: Text(
              backLabel,
              style: TextStyle(color: palette.primaryForeground),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            title,
            style: TextStyle(
              color: palette.primaryForeground,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: TextStyle(
              color: palette.primaryForeground.withValues(alpha: 0.82),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
