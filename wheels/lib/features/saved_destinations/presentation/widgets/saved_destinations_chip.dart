import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../domain/entities/saved_destination.dart';

class SavedDestinationsChip extends StatelessWidget {
  const SavedDestinationsChip({
    super.key,
    required this.destination,
    required this.onTap,
  });

  final SavedDestination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(
        Icons.push_pin_outlined,
        size: 16,
        color: palette.secondary,
      ),
      backgroundColor: palette.secondarySoft,
      side: BorderSide(color: palette.border),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          destination.displayLabel,
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
