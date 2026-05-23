import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../domain/entities/saved_destination.dart';
import '../providers/saved_destinations_providers.dart';

class SavedDestinationDetailScreen extends ConsumerWidget {
  const SavedDestinationDetailScreen({required this.localId, super.key});

  final int localId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationAsync = ref.watch(savedDestinationByIdProvider(localId));
    final bootstrapAsync = ref.watch(savedDestinationsBootstrapProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: const Text('Destination detail'),
      ),
      body: destinationAsync.when(
        data: (destination) {
          if (destination == null) {
            return const _DetailMissingState();
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              _HeroCard(destination: destination),
              const SizedBox(height: AppSpacing.m),
              _DistanceAndStats(
                destination: destination,
                currentPosition: bootstrapAsync.valueOrNull?.position,
              ),
              const SizedBox(height: AppSpacing.m),
              _DetailActions(destination: destination),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.destination});

  final SavedDestination destination;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            destination.displayLabel,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            destination.address,
            style: TextStyle(
              color: palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              _StatPill(label: '${destination.useCount} saved uses'),
              _StatPill(label: destination.coordinatesLabel),
              if (destination.pendingSync)
                _StatPill(label: 'Pending sync'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistanceAndStats extends ConsumerWidget {
  const _DistanceAndStats({
    required this.destination,
    required this.currentPosition,
  });

  final SavedDestination destination;
  final Position? currentPosition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final userId = ref.watch(savedDestinationsCurrentUserIdProvider);
    final position = currentPosition;
    return FutureBuilder<List<Object?>>(
      future: Future.wait<Object?>([
        if (position != null && destination.localId != null)
          ref.read(savedDestinationsRepositoryProvider).loadDistancesForCurrentLocation(
                currentLatitude: position.latitude,
                currentLongitude: position.longitude,
                destinations: <SavedDestination>[destination],
              )
        else
          Future<Map<int, double>>.value(const <int, double>{}),
        if (userId != null)
          ref.read(savedDestinationsRepositoryProvider).loadUsageStats(
                userId: userId,
                destination: destination,
              )
        else
          Future<SavedDestinationUsageStats>.value(
            SavedDestinationUsageStats.empty,
          ),
      ]),
      builder: (context, snapshot) {
        final distances = snapshot.data == null
            ? const <int, double>{}
            : snapshot.data![0] as Map<int, double>;
        final stats = snapshot.data == null
            ? SavedDestinationUsageStats.empty
            : snapshot.data![1] as SavedDestinationUsageStats;
        final distance = destination.localId == null
            ? null
            : distances[destination.localId!];

        return Container(
          padding: const EdgeInsets.all(AppSpacing.l),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip planner snapshot',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              _InfoRow(
                label: 'Distance from current location',
                value: distance == null
                    ? 'Location unavailable'
                    : '${distance.toStringAsFixed(1)} km',
              ),
              _InfoRow(
                label: 'Total ride count',
                value: '${stats.totalRideCount}',
              ),
              _InfoRow(
                label: 'Average price per seat',
                value: stats.totalRideCount == 0
                    ? 'No history yet'
                    : '\$${stats.averagePricePerSeat.toStringAsFixed(0)} COP',
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Last 5 visits',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              if (stats.lastVisitLabels.isEmpty)
                Text(
                  'No recent rides toward this destination were found in local history.',
                  style: TextStyle(color: palette.textSecondary),
                )
              else
                for (final visit in stats.lastVisitLabels)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.history,
                          size: 16,
                          color: palette.secondary,
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Text(
                            visit,
                            style: TextStyle(color: palette.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailActions extends ConsumerWidget {
  const _DetailActions({required this.destination});

  final SavedDestination destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Use this destination',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Save it as your latest quick pick and jump directly into ride search or ride creation.',
            style: TextStyle(
              color: palette.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final userId = ref.read(savedDestinationsCurrentUserIdProvider);
                final localId = destination.localId;
                if (userId == null || localId == null) {
                  return;
                }
                await ref.read(savedDestinationsRepositoryProvider).saveLastQuickPick(
                      userId: userId,
                      localId: localId,
                    );
                if (!context.mounted) {
                  return;
                }
                context.go(AppRoutes.ridesWithSavedDestination(localId));
              },
              icon: const Icon(Icons.search),
              label: const Text('Plan in ride search'),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final userId = ref.read(savedDestinationsCurrentUserIdProvider);
                final localId = destination.localId;
                if (userId == null || localId == null) {
                  return;
                }
                await ref.read(savedDestinationsRepositoryProvider).saveLastQuickPick(
                      userId: userId,
                      localId: localId,
                    );
                if (!context.mounted) {
                  return;
                }
                context.go(AppRoutes.createRideWithSavedDestination(localId));
              },
              icon: const Icon(Icons.add_road_outlined),
              label: const Text('Use in create ride'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label});

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
        color: palette.secondarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.secondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailMissingState extends StatelessWidget {
  const _DetailMissingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Text(
          'This saved destination is no longer available on this device.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
