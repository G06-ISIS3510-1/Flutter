import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../domain/entities/saved_destination.dart';

class SavedDestinationTile extends StatelessWidget {
  const SavedDestinationTile({
    super.key,
    required this.destination,
    required this.onTap,
    this.distanceKm,
    this.onDelete,
  });

  final SavedDestination destination;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final subtitle = destination.address.trim() == destination.displayLabel
        ? destination.coordinatesLabel
        : destination.address;

    return Dismissible(
      key: ValueKey('saved-destination-${destination.localId}'),
      direction: onDelete == null ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        decoration: BoxDecoration(
          color: palette.error,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              children: [
                _Thumbnail(
                  destination: destination,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              destination.displayLabel,
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (destination.pendingSync)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: palette.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Pending sync',
                                style: TextStyle(
                                  color: palette.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: palette.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Wrap(
                        spacing: AppSpacing.s,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _MetaPill(
                            label: '${destination.useCount} uses',
                          ),
                          if (distanceKm != null)
                            _MetaPill(
                              label: '${distanceKm!.toStringAsFixed(1)} km away',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Icon(Icons.chevron_right, color: palette.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.destination});

  final SavedDestination destination;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final thumbnailUrl = destination.thumbnailUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: 68,
        height: 68,
        child: thumbnailUrl == null || thumbnailUrl.trim().isEmpty
            ? Container(
                color: palette.secondarySoft,
                child: Icon(
                  Icons.place_outlined,
                  color: palette.secondary,
                  size: 28,
                ),
              )
            : CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                memCacheWidth: 136,
                memCacheHeight: 136,
                placeholder: (context, imageUrl) => Container(
                  color: palette.secondarySoft,
                  child: Icon(
                    Icons.photo_outlined,
                    color: palette.secondary,
                  ),
                ),
                errorWidget: (context, imageUrl, error) => Container(
                  color: palette.secondarySoft,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: palette.secondary,
                  ),
                ),
              ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: palette.input,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
