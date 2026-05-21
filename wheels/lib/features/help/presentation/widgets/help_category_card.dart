import 'package:flutter/material.dart';

import '../../../../theme/app_radius.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../domain/entities/help_category.dart';

class HelpCategoryCard extends StatelessWidget {
  const HelpCategoryCard({
    required this.category,
    required this.articleCount,
    required this.onTap,
    super.key,
  });

  final HelpCategory category;
  final int articleCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _categoryIcon(category),
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.label,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                articleCount == 1 ? '1 article' : '$articleCount articles',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(HelpCategory category) {
  return switch (category) {
    HelpCategory.account => Icons.account_circle_outlined,
    HelpCategory.payments => Icons.payments_outlined,
    HelpCategory.rides => Icons.directions_car_outlined,
    HelpCategory.safety => Icons.shield_outlined,
    HelpCategory.drivers => Icons.local_taxi_outlined,
  };
}
