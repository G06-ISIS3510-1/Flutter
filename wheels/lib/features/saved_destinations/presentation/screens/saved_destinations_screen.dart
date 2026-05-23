import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/services/current_location_service.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_gradient_header.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/saved_destination.dart';
import '../../domain/repositories/saved_destinations_repository.dart';
import '../providers/saved_destinations_providers.dart';
import '../widgets/saved_destination_tile.dart';

class SavedDestinationsScreen extends ConsumerStatefulWidget {
  const SavedDestinationsScreen({super.key});

  @override
  ConsumerState<SavedDestinationsScreen> createState() =>
      _SavedDestinationsScreenState();
}

class _SavedDestinationsScreenState
    extends ConsumerState<SavedDestinationsScreen> {
  final _currentLocationService = const CurrentLocationService();
  bool _isAddingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(savedDestinationsFeatureInitProvider);
    });
  }

  Future<void> _openDestinationEditor({SavedDestination? existing}) async {
    final result = await showModalBottomSheet<_SavedDestinationDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SavedDestinationEditorSheet(existing: existing),
    );

    if (!mounted || result == null) {
      return;
    }

    final userId = ref.read(savedDestinationsCurrentUserIdProvider);
    if (userId == null) {
      return;
    }

    try {
      final locations = await locationFromAddress(result.address);
      final coordinates = locations.isEmpty
          ? null
          : locations.first;
      if (coordinates == null) {
        throw Exception('We could not resolve that address to map coordinates.');
      }

      final repository = ref.read(savedDestinationsRepositoryProvider);
      final destination = SavedDestination(
        localId: existing?.localId,
        userId: userId,
        name: result.name.trim(),
        address: result.address.trim(),
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        createdAt: existing?.createdAt ?? DateTime.now().toUtc(),
        lastUsedAt: existing?.lastUsedAt ?? DateTime.now().toUtc(),
        useCount: existing?.useCount ?? 0,
        remoteId: existing?.remoteId,
        thumbnailUrl: result.thumbnailUrl.trim().isEmpty
            ? null
            : result.thumbnailUrl.trim(),
        pendingSync: true,
      );
      await repository.saveDestination(destination);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              existing == null
                  ? 'Destination saved locally.'
                  : 'Destination updated locally.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
    }
  }

  Future<void> _deleteDestination(SavedDestination destination) async {
    final userId = ref.read(savedDestinationsCurrentUserIdProvider);
    if (userId == null || destination.localId == null) {
      return;
    }

    await ref.read(savedDestinationsRepositoryProvider).markDestinationDeleted(
      userId: userId,
      localId: destination.localId!,
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${destination.displayLabel} removed locally.')),
      );
  }

  Future<void> _addCurrentLocationQuickly() async {
    if (_isAddingCurrentLocation) {
      return;
    }

    setState(() {
      _isAddingCurrentLocation = true;
    });

    try {
      final userId = ref.read(savedDestinationsCurrentUserIdProvider);
      if (userId == null) {
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Enable location services first.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to quick-save your current place.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final address = await _currentLocationService.getCurrentAddress();

      await ref.read(savedDestinationsRepositoryProvider).saveDestination(
        SavedDestination(
          userId: userId,
          name: 'Current location',
          address: address,
          latitude: position.latitude,
          longitude: position.longitude,
          createdAt: DateTime.now().toUtc(),
          lastUsedAt: DateTime.now().toUtc(),
          useCount: 0,
          pendingSync: true,
        ),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Current location saved.')),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingCurrentLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final role = ref.watch(currentUserRoleProvider);
    final destinationsAsync = ref.watch(savedDestinationsStreamProvider);
    final bootstrapAsync = ref.watch(savedDestinationsBootstrapProvider);
    final trendingAsync = ref.watch(savedDestinationsTrendingProvider);
    final selectedSort = ref.watch(savedDestinationsSortProvider);

    return Scaffold(
      backgroundColor: palette.background,
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.middle,
        role: role,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDestinationEditor,
        backgroundColor: palette.secondary,
        foregroundColor: palette.primaryForeground,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add destination'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: AppGradientHeader(
                    title: 'Saved Destinations',
                    subtitle: 'Plan campus trips faster with your favorite places',
                    onBack: () => context.pop(),
                    height: 170,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _TopPanel(
                          selectedSort: selectedSort,
                          onSortChanged: (sort) {
                            ref.read(savedDestinationsSortProvider.notifier).state =
                                sort;
                          },
                          onQuickAddCurrentLocation: _isAddingCurrentLocation
                              ? null
                              : _addCurrentLocationQuickly,
                          isAddingCurrentLocation: _isAddingCurrentLocation,
                          lastQuickPick:
                              bootstrapAsync.valueOrNull?.lastQuickPick,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.l),
                      ),
                      SliverToBoxAdapter(
                        child: _TrendingSection(trendingAsync: trendingAsync),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.l),
                      ),
                      destinationsAsync.when(
                        data: (destinations) {
                          final position = bootstrapAsync.valueOrNull?.position;
                          if (destinations.isEmpty) {
                            return SliverToBoxAdapter(
                              child: _EmptyState(
                                onAddPressed: _openDestinationEditor,
                              ),
                            );
                          }

                          return SliverList.builder(
                            itemCount: destinations.length,
                            itemBuilder: (context, index) {
                              final destination = destinations[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                                child: FutureBuilder<Map<int, double>>(
                                  future: position == null || destination.localId == null
                                      ? Future<Map<int, double>>.value(
                                          const <int, double>{},
                                        )
                                      : ref
                                          .read(savedDestinationsRepositoryProvider)
                                          .loadDistancesForCurrentLocation(
                                            currentLatitude: position.latitude,
                                            currentLongitude: position.longitude,
                                            destinations: <SavedDestination>[
                                              destination,
                                            ],
                                          ),
                                  builder: (context, snapshot) {
                                    final distance = destination.localId == null
                                        ? null
                                        : snapshot.data?[destination.localId!];
                                    return SavedDestinationTile(
                                      destination: destination,
                                      distanceKm: distance,
                                      onTap: () {
                                        if (destination.localId == null) {
                                          return;
                                        }
                                        context.push(
                                          AppRoutes.savedDestinationDetailById(
                                            destination.localId!,
                                          ),
                                        );
                                      },
                                      onDelete: () => _deleteDestination(destination),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                        error: (error, _) => SliverToBoxAdapter(
                          child: _ErrorState(message: error.toString()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendingSection extends StatelessWidget {
  const _TrendingSection({required this.trendingAsync});

  final AsyncValue<List<SavedDestinationTrendingEntry>> trendingAsync;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending on campus',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Live BQ-M4 snapshot of the destinations students save most often.',
            style: TextStyle(
              color: palette.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          trendingAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return Text(
                  'No shared destination trends are available yet.',
                  style: TextStyle(color: palette.textSecondary),
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < entries.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == entries.length - 1 ? 0 : AppSpacing.s,
                      ),
                      child: _TrendingRow(
                        rank: index + 1,
                        entry: entries[index],
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: LinearProgressIndicator(),
            ),
            error: (error, stackTrace) => Text(
              'Campus trends are temporarily unavailable.',
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingRow extends StatelessWidget {
  const _TrendingRow({
    required this.rank,
    required this.entry,
  });

  final int rank;
  final SavedDestinationTrendingEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: palette.secondarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: TextStyle(
              color: palette.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.address,
                style: TextStyle(
                  color: palette.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Text(
          '${entry.saveCount} saves',
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TopPanel extends StatelessWidget {
  const _TopPanel({
    required this.selectedSort,
    required this.onSortChanged,
    required this.onQuickAddCurrentLocation,
    required this.isAddingCurrentLocation,
    required this.lastQuickPick,
  });

  final SavedDestinationsSort selectedSort;
  final ValueChanged<SavedDestinationsSort> onSortChanged;
  final VoidCallback? onQuickAddCurrentLocation;
  final bool isAddingCurrentLocation;
  final SavedDestination? lastQuickPick;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your saved places',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onQuickAddCurrentLocation,
                icon: isAddingCurrentLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Save current'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            lastQuickPick == null
                ? 'No quick pick yet. Your most recent destination will appear here.'
                : 'Last quick pick: ${lastQuickPick!.displayLabel}',
            style: TextStyle(
              color: palette.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            children: [
              ChoiceChip(
                label: const Text('Recent'),
                selected: selectedSort == SavedDestinationsSort.recent,
                onSelected: (_) => onSortChanged(SavedDestinationsSort.recent),
              ),
              ChoiceChip(
                label: const Text('Most used'),
                selected: selectedSort == SavedDestinationsSort.useCount,
                onSelected: (_) => onSortChanged(SavedDestinationsSort.useCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Icon(Icons.route_outlined, size: 64, color: palette.secondary),
          const SizedBox(height: AppSpacing.s),
          Text(
            'No destinations saved yet',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Save your most frequent places to prefill trip planning with one tap.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, height: 1.35),
          ),
          const SizedBox(height: AppSpacing.m),
          FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add first destination'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 54, color: palette.error),
          const SizedBox(height: AppSpacing.s),
          Text(
            'We could not load your saved destinations',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SavedDestinationDraft {
  const _SavedDestinationDraft({
    required this.name,
    required this.address,
    required this.thumbnailUrl,
  });

  final String name;
  final String address;
  final String thumbnailUrl;
}

class _SavedDestinationEditorSheet extends StatefulWidget {
  const _SavedDestinationEditorSheet({this.existing});

  final SavedDestination? existing;

  @override
  State<_SavedDestinationEditorSheet> createState() =>
      _SavedDestinationEditorSheetState();
}

class _SavedDestinationEditorSheetState
    extends State<_SavedDestinationEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _thumbnailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _addressController = TextEditingController(
      text: widget.existing?.address ?? '',
    );
    _thumbnailController = TextEditingController(
      text: widget.existing?.thumbnailUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.xl,
        AppSpacing.m,
        insets + AppSpacing.m,
      ),
      child: Material(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existing == null
                      ? 'Add saved destination'
                      : 'Edit destination',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'Home, Library, Main Gate...',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a short label.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter an address or campus place',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter an address.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _thumbnailController,
                  decoration: const InputDecoration(
                    labelText: 'Thumbnail URL (optional)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          Navigator.of(context).pop(
                            _SavedDestinationDraft(
                              name: _nameController.text,
                              address: _addressController.text,
                              thumbnailUrl: _thumbnailController.text,
                            ),
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
