import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/utils/app_formatter.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../domain/entities/ride_history_entity.dart';
import '../providers/ride_history_providers.dart';

String _formatDeparture(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$m $ampm';
}

class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final role = ref.watch(currentUserRoleProvider);
    final isOnline = ref.watch(connectivityStatusProvider).valueOrNull ?? true;
    final historyAsync = ref.watch(rideHistoryProvider);
    final historyState = historyAsync.valueOrNull;
    final entries = historyState?.entries ?? const <RideHistoryEntity>[];
    final isUsingCachedFallback =
        historyState?.isFromCache == true && entries.isNotEmpty;
    final hasRemoteError = historyState?.hasRemoteError ?? false;
    final isLoading = historyAsync.isLoading && entries.isEmpty;
    final isEmpty = entries.isEmpty;

    return AppScaffold(
      title: 'Ride History',
      backgroundColor: palette.background,
      maxScrollableWidth: 440,
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.history,
        role: role,
      ),
      child: ListView(
        children: [
          const SizedBox(height: AppSpacing.s),
          if (isUsingCachedFallback) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: _StaleNotice(
                isOnline: isOnline,
                hasRemoteError: hasRemoteError,
                onRetry: isOnline
                    ? () => ref.read(rideHistoryProvider.notifier).refresh()
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          if (historyAsync.hasError && entries.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: _HistoryLoadErrorNotice(
                onRetry: isOnline
                    ? () => ref.read(rideHistoryProvider.notifier).refresh()
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          if (isLoading && isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: 48,
              ),
              child: _EmptyState(isOnline: isOnline),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: Column(
                children: entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s),
                        child: _RideHistoryCard(entry: entry),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }
}

class _StaleNotice extends StatelessWidget {
  const _StaleNotice({
    required this.isOnline,
    required this.hasRemoteError,
    this.onRetry,
  });

  final bool isOnline;
  final bool hasRemoteError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.sync_outlined : Icons.wifi_off_outlined,
            color: palette.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isOnline
                  ? hasRemoteError
                      ? 'Live history could not be refreshed. Showing the latest cached history from this device.'
                      : 'Showing locally cached history while fresh data is loading.'
                  : 'You are offline. Showing the last locally saved history.',
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class _HistoryLoadErrorNotice extends StatelessWidget {
  const _HistoryLoadErrorNotice({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: palette.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'We could not load your ride history right now, and there is no saved cache on this device yet.',
              style: TextStyle(
                color: palette.textPrimary,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        Icon(Icons.history_outlined, size: 56, color: palette.textSecondary),
        const SizedBox(height: AppSpacing.m),
        Text(
          isOnline ? 'No rides found' : 'No cached history available',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isOnline
              ? 'Your ride history will appear here once you complete or join a ride.'
              : 'Connect to the internet to load your ride history.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textSecondary),
        ),
      ],
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  const _RideHistoryCard({required this.entry});

  final RideHistoryEntity entry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return GestureDetector(
      onTap: () => context.go(AppRoutes.rideDetailsById(entry.rideId)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _RouteLabel(
                    origin: entry.origin,
                    destination: entry.destination,
                    palette: palette,
                  ),
                ),
                const SizedBox(width: 8),
                _RoleBadge(isDriver: entry.isDriver, palette: palette),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: palette.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDeparture(entry.departureAt),
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _StatusBadge(entry: entry, palette: palette),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 14,
                  color: palette.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  AppFormatter.cop(entry.pricePerSeat),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (!entry.isDriver) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: palette.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.driverName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLabel extends StatelessWidget {
  const _RouteLabel({
    required this.origin,
    required this.destination,
    required this.palette,
  });

  final String origin;
  final String destination;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trip_origin, size: 12, color: palette.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                origin,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 12, color: palette.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                destination,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isDriver, required this.palette});

  final bool isDriver;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDriver
            ? palette.primary.withValues(alpha: 0.12)
            : palette.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isDriver ? 'Driver' : 'Passenger',
        style: TextStyle(
          color: isDriver ? palette.primary : palette.accent,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.entry, required this.palette});

  final RideHistoryEntity entry;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    if (entry.isCompleted) {
      bg = palette.accentSoft;
      fg = palette.accent;
      label = 'Completed';
    } else if (entry.isCancelled) {
      bg = palette.secondary.withValues(alpha: 0.12);
      fg = palette.secondary;
      label = 'Cancelled';
    } else if (entry.isInProgress) {
      bg = palette.primary.withValues(alpha: 0.12);
      fg = palette.primary;
      label = 'In Progress';
    } else {
      bg = palette.border;
      fg = palette.textSecondary;
      label = 'Open';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
