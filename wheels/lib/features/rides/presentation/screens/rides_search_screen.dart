import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/services/current_location_service.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_gradient_header.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../data/datasources/rides_search_local_datasource.dart';
import '../../data/models/local_ride_search_cache_model.dart';
import '../../domain/entities/rides_entity.dart';
import '../models/ride_listing.dart';
import '../providers/rides_providers.dart';

class RidesSearchScreen extends ConsumerStatefulWidget {
  const RidesSearchScreen({super.key});

  @override
  ConsumerState<RidesSearchScreen> createState() => _RidesSearchScreenState();
}

class _RidesSearchScreenState extends ConsumerState<RidesSearchScreen> {
  final _currentLocationService = const CurrentLocationService();

  static const List<String> _campusLocations = <String>[
    'Main Campus',
    'North Residence Hall',
    'Engineering Building',
    'Student Center',
    'Downtown',
    'Library',
    'South Residence Hall',
  ];

  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _dateController = TextEditingController();

  late final RidesSearchLocalDataSource _ridesSearchLocalDataSource;
  DateTime _selectedDate = DateTime.now();
  late DateTime _appliedDate;
  RideSortOption _sort = RideSortOption.smartMatch;
  bool _isResolvingOriginFromGps = false;
  bool _hasTriggeredSearch = false;
  String? _originLocationError;
  String? _currentLocationSuggestion;
  String _appliedOriginQuery = '';
  String _appliedDestinationQuery = '';
  LocalRideSearchCacheModel? _cachedSearchCache;
  String? _lastSavedCacheSignature;

  @override
  void initState() {
    super.initState();
    _ridesSearchLocalDataSource = ref.read(ridesSearchLocalDataSourceProvider);
    _appliedDate = _dateOnly(_selectedDate);
    _dateController.text = _formatDate(_selectedDate);
    Future.microtask(_initializeSearchState);
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _prefillOriginWithCurrentLocation() async {
    if (_originController.text.trim().isNotEmpty) {
      return;
    }

    try {
      final address = await _currentLocationService.getCurrentAddress();
      if (!mounted) {
        return;
      }

      setState(() {
        _originController.text = address;
        _currentLocationSuggestion = address;
        _originLocationError = null;
      });
    } catch (_) {
      // Leave the field empty if location cannot be resolved on screen load.
    }
  }

  Future<void> _initializeSearchState() async {
    await _restoreLatestSearch();
    await _prefillOriginWithCurrentLocation();
  }

  Future<void> _restoreLatestSearch() async {
    final cache = await _ridesSearchLocalDataSource.loadLatestSearch();
    if (!mounted || cache == null) {
      return;
    }

    final filters = cache.filters;
    setState(() {
      _cachedSearchCache = cache;
      _hasTriggeredSearch = true;
      _selectedDate = _dateOnly(filters.selectedDate);
      _appliedDate = _selectedDate;
      _sort = filters.sort;
      _originController.text = filters.originQuery;
      _destinationController.text = filters.destinationQuery;
      _dateController.text = _formatDate(_selectedDate);
      _appliedOriginQuery = filters.originQuery.trim().toLowerCase();
      _appliedDestinationQuery = filters.destinationQuery.trim().toLowerCase();
      _lastSavedCacheSignature = _cacheSignature(cache);
    });
  }

  Future<void> _useCurrentLocationAsOrigin() async {
    setState(() {
      _isResolvingOriginFromGps = true;
      _originLocationError = null;
    });

    try {
      final address = await _currentLocationService.getCurrentAddress();
      if (!mounted) {
        return;
      }

      setState(() {
        _originController.text = address;
        _currentLocationSuggestion = address;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Origin updated from your current location.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _originLocationError = error.toString().replaceFirst('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _originLocationError ?? 'Unable to read current location.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingOriginFromGps = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 30)),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
      _appliedDate = _dateOnly(_selectedDate);
      _dateController.text = _formatDate(_selectedDate);
    });
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  List<String> _locationSuggestionsFor(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    final baseSuggestions = <String>[
      ...(_currentLocationSuggestion == null
          ? const <String>[]
          : <String>[_currentLocationSuggestion!]),
      ..._campusLocations,
    ];

    final uniqueSuggestions = baseSuggestions.toSet().toList();
    if (normalizedQuery.isEmpty) {
      return uniqueSuggestions;
    }

    return uniqueSuggestions.where((location) {
      return location.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  int _compareBySmartMatch(RidesEntity left, RidesEntity right) {
    final leftScore = _smartMatchScore(left);
    final rightScore = _smartMatchScore(right);

    final scoreComparison = rightScore.compareTo(leftScore);
    if (scoreComparison != 0) {
      return scoreComparison;
    }

    final ratingComparison = right.driverRating.compareTo(left.driverRating);
    if (ratingComparison != 0) {
      return ratingComparison;
    }

    return left.departureAt.compareTo(right.departureAt);
  }

  double _smartMatchScore(RidesEntity ride) {
    final now = DateTime.now();
    final minutesUntilDeparture = ride.departureAt.difference(now).inMinutes;

    final ratingScore = ride.driverRating * 12;
    final punctualityScore = ride.onTimeRate * 0.35;
    final reviewConfidenceScore = ride.reviewCount.clamp(0, 20).toDouble();
    final verificationBonus = ride.verifiedByUniversity ? 30.0 : 0.0;
    final seatsScore = ride.availableSeats.clamp(0, 4) * 4.0;
    final pricePenalty = (ride.pricePerSeat / 1000) * 2.0;

    double departureScore;
    if (minutesUntilDeparture < 0) {
      departureScore = -50;
    } else if (minutesUntilDeparture <= 20) {
      departureScore = 8;
    } else if (minutesUntilDeparture <= 90) {
      departureScore = 16;
    } else if (minutesUntilDeparture <= 180) {
      departureScore = 10;
    } else {
      departureScore = 4;
    }

    return ratingScore +
        punctualityScore +
        reviewConfidenceScore +
        verificationBonus +
        seatsScore +
        departureScore -
        pricePenalty;
  }

  List<RidesEntity> _applyFilters(List<RidesEntity> rides) {
    final filtered = rides.where((ride) {
      final rideDay = _dateOnly(ride.departureAt);
      if (rideDay.isBefore(_appliedDate)) {
        return false;
      }

      final originMatch =
          _appliedOriginQuery.isEmpty ||
          ride.origin.toLowerCase().contains(_appliedOriginQuery);
      final destinationMatch =
          _appliedDestinationQuery.isEmpty ||
          ride.destination.toLowerCase().contains(_appliedDestinationQuery);
      return originMatch && destinationMatch;
    }).toList();

    filtered.sort(
      (a, b) => switch (_sort) {
        RideSortOption.smartMatch => _compareBySmartMatch(a, b),
        RideSortOption.earliest => a.departureAt.compareTo(b.departureAt),
        RideSortOption.cheapest => a.pricePerSeat.compareTo(b.pricePerSeat),
        RideSortOption.highestRated => b.driverRating.compareTo(a.driverRating),
      },
    );

    return filtered;
  }

  Future<void> _clearFilters() async {
    final now = _dateOnly(DateTime.now());

    setState(() {
      _hasTriggeredSearch = false;
      _sort = RideSortOption.smartMatch;
      _selectedDate = now;
      _appliedDate = now;
      _originController.clear();
      _destinationController.clear();
      _dateController.text = _formatDate(now);
      _appliedOriginQuery = '';
      _appliedDestinationQuery = '';
      _cachedSearchCache = null;
      _lastSavedCacheSignature = null;
    });

    await _ridesSearchLocalDataSource.clearLatestSearch();
    if (!mounted) {
      return;
    }

    await _prefillOriginWithCurrentLocation();
  }

  Future<void> _handleDestinationChanged(String value) async {
    if (value.trim().isNotEmpty || _appliedDestinationQuery.isEmpty) {
      return;
    }

    setState(() {
      _appliedDestinationQuery = '';
    });

    final rides = ref.read(availableRidesProvider).valueOrNull;
    if (rides != null) {
      await _persistLatestSuccessfulSearch(_applyFilters(rides));
    }
  }

  int _countFilteredRides(
    List<RidesEntity> rides, {
    required String originQuery,
    required String destinationQuery,
    required DateTime selectedDate,
  }) {
    final normalizedOriginQuery = originQuery.trim().toLowerCase();
    final normalizedDestinationQuery = destinationQuery.trim().toLowerCase();
    final appliedDay = _dateOnly(selectedDate);

    return rides.where((ride) {
      final rideDay = _dateOnly(ride.departureAt);
      if (rideDay.isBefore(appliedDay)) {
        return false;
      }

      final originMatch =
          normalizedOriginQuery.isEmpty ||
          ride.origin.toLowerCase().contains(normalizedOriginQuery);
      final destinationMatch =
          normalizedDestinationQuery.isEmpty ||
          ride.destination.toLowerCase().contains(normalizedDestinationQuery);

      return originMatch && destinationMatch;
    }).length;
  }

  Future<void> _logRideSearchSubmitted({
    required String originQuery,
    required String destinationQuery,
    required DateTime selectedDate,
    required RideSortOption sortOption,
    required int resultsCount,
  }) async {
    final normalizedOrigin = originQuery.trim().toLowerCase();
    final usedCurrentLocation =
        _currentLocationSuggestion != null &&
        normalizedOrigin.isNotEmpty &&
        normalizedOrigin == _currentLocationSuggestion!.trim().toLowerCase();

    try {
      await ref
          .read(firebaseAnalyticsProvider)
          .logEvent(
            name: 'ride_search_submitted',
            parameters: <String, Object>{
              'origin_query': originQuery.trim().isEmpty
                  ? 'any'
                  : originQuery.trim(),
              'destination_query': destinationQuery.trim().isEmpty
                  ? 'any'
                  : destinationQuery.trim(),
              'selected_date': _formatDate(selectedDate),
              'sort_option': sortOption.name,
              'results_count': resultsCount,
              'used_current_location': usedCurrentLocation ? 1 : 0,
              'user_role': ref.read(currentUserRoleProvider).name,
            },
          );
    } catch (_) {
      // Analytics should never block the ride search flow.
    }
  }

  Future<void> _applySearch() async {
    final nextOriginQuery = _originController.text.trim();
    final nextDestinationQuery = _destinationController.text.trim();
    final selectedDate = _dateOnly(_selectedDate);
    final availableRides =
        ref.read(availableRidesProvider).valueOrNull ?? const <RidesEntity>[];
    final resultsCount = _countFilteredRides(
      availableRides,
      originQuery: nextOriginQuery,
      destinationQuery: nextDestinationQuery,
      selectedDate: selectedDate,
    );

    setState(() {
      _hasTriggeredSearch = true;
      _appliedOriginQuery = nextOriginQuery.toLowerCase();
      _appliedDestinationQuery = nextDestinationQuery.toLowerCase();
      _appliedDate = selectedDate;
    });

    unawaited(
      _logRideSearchSubmitted(
        originQuery: nextOriginQuery,
        destinationQuery: nextDestinationQuery,
        selectedDate: selectedDate,
        sortOption: _sort,
        resultsCount: resultsCount,
      ),
    );

    final ridesAsync = ref.read(availableRidesProvider);
    final rides = ridesAsync.valueOrNull;
    if (rides != null) {
      await _persistLatestSuccessfulSearch(_applyFilters(rides));
    }
  }

  Future<void> _persistLatestSuccessfulSearch(List<RidesEntity> results) async {
    if (!_hasTriggeredSearch) {
      return;
    }

    final cache = LocalRideSearchCacheModel.create(
      filters: LocalRideSearchFiltersModel(
        originQuery: _originController.text.trim(),
        destinationQuery: _destinationController.text.trim(),
        selectedDate: _appliedDate,
        sort: _sort,
      ),
      results: results,
    );
    final nextSignature = _cacheSignature(cache);
    if (nextSignature == _lastSavedCacheSignature) {
      return;
    }

    await _ridesSearchLocalDataSource.saveLatestSearch(cache);
    if (!mounted) {
      return;
    }

    setState(() {
      _cachedSearchCache = cache;
      _lastSavedCacheSignature = nextSignature;
    });
  }

  String _cacheSignature(LocalRideSearchCacheModel cache) {
    final resultIds = cache.results.map((result) => result.id).join('|');
    final filters = cache.filters;
    return [
      filters.originQuery.trim().toLowerCase(),
      filters.destinationQuery.trim().toLowerCase(),
      _dateOnly(filters.selectedDate).toIso8601String(),
      filters.sort.name,
      resultIds,
    ].join('::');
  }

  Widget _buildResultsSection(
    List<RidesEntity> results, {
    bool isCached = false,
  }) {
    return Column(
      children: [
        if (isCached) ...[
          _cachedResultsNotice(),
          const SizedBox(height: AppSpacing.m),
        ],
        _sectionTitle('Available Drivers', '${results.length} rides'),
        const SizedBox(height: AppSpacing.s),
        if (results.isEmpty) _emptyState(isCached: isCached),
        for (var index = 0; index < results.length; index++) ...[
          _RideResultCard(
            ride: results[index],
            isBestMatch: _sort == RideSortOption.smartMatch && index == 0,
            onTap: () =>
                context.go(AppRoutes.rideDetailsById(results[index].id)),
          ),
          const SizedBox(height: AppSpacing.m),
        ],
      ],
    );
  }

  Widget _cachedResultsNotice() {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: palette.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.offline_bolt_outlined, color: palette.secondary),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              'Showing the latest saved search results while live data is unavailable.',
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final role = ref.watch(currentUserRoleProvider);
    final ridesAsync = ref.watch(availableRidesProvider);

    return AppScaffold(
      title: 'Rides',
      showAppBar: false,
      backgroundColor: palette.background,
      scrollableHeader: AppGradientHeader(
        title: 'Find a Ride',
        subtitle: 'Available rides from your university',
        onBack: () => context.go(AppRoutes.dashboard),
        height: 160,
      ),
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.middle,
        role: role,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          children: [
            _searchCard(),
            const SizedBox(height: AppSpacing.m),
            _sortBar(),
            if (_sort == RideSortOption.smartMatch) ...[
              const SizedBox(height: AppSpacing.m),
              _smartMatchNotice(),
            ],
            const SizedBox(height: AppSpacing.l),
            ridesAsync.when(
              data: (rides) {
                final results = _applyFilters(rides);
                unawaited(_persistLatestSuccessfulSearch(results));
                return _buildResultsSection(results);
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _loadError(error),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ),
      ),
    );
  }

  Widget _searchCard() {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _autocompleteField(
            controller: _originController,
            label: 'Origin',
            hint: 'Where are you leaving from?',
            icon: Icons.my_location,
            iconColor: palette.primary,
            suffixIcon: _isResolvingOriginFromGps
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Use current location',
                    onPressed: _useCurrentLocationAsOrigin,
                    icon: Icon(Icons.near_me_outlined, color: palette.primary),
                  ),
          ),
          if (_originLocationError != null) ...[
            const SizedBox(height: AppSpacing.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: palette.error),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _originLocationError!,
                    style: TextStyle(color: palette.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.s),
          _autocompleteField(
            controller: _destinationController,
            label: 'Destination',
            hint: 'Where are you going?',
            icon: Icons.place_outlined,
            iconColor: palette.accent,
          ),
          const SizedBox(height: AppSpacing.s),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _pickDate,
            decoration: InputDecoration(
              labelText: 'Date',
              hintText: 'Select trip date',
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                color: palette.secondary,
              ),
              suffixIcon: Icon(
                Icons.keyboard_arrow_down,
                color: palette.textSecondary,
              ),
              filled: true,
              fillColor: palette.input,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _applySearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.accentForeground,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text(
                      'Search Rides',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.primary,
                    side: BorderSide(color: palette.border),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Clear',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortBar() {
    final palette = context.palette;

    return Row(
      children: [
        Icon(Icons.filter_list, color: palette.primary),
        const SizedBox(width: AppSpacing.s),
        Text(
          'Sort by:',
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: RideSortOption.values.map((option) {
                final selected = option == _sort;

                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s),
                  child: ChoiceChip(
                    label: Text(option.label),
                    avatar: Icon(
                      option.icon,
                      size: 16,
                      color: selected
                          ? palette.primaryForeground
                          : palette.primary,
                    ),
                    selected: selected,
                    backgroundColor: palette.card,
                    selectedColor: palette.primary,
                    side: BorderSide(
                      color: selected ? palette.primary : palette.border,
                    ),
                    labelStyle: TextStyle(
                      color: selected
                          ? palette.primaryForeground
                          : palette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _sort = option;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _smartMatchNotice() {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: palette.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: palette.primary),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Match is on',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Results are ranked using driver rating, punctuality, university verification, available seats, price, and how soon the ride departs.',
                  style: TextStyle(color: palette.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String left, String right) {
    final palette = context.palette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          left,
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        Text(
          right,
          style: TextStyle(
            color: palette.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _emptyState({bool isCached = false}) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Icon(Icons.route, size: 64, color: palette.secondary),
          const SizedBox(height: AppSpacing.s),
          Text(
            'No rides found',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isCached
                ? 'These are the latest results stored on this device.'
                : 'Try changing origin, destination or date.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _loadError(Object error) {
    final cachedResults = _cachedSearchCache?.toEntities();
    if (cachedResults != null) {
      return _buildResultsSection(cachedResults, isCached: true);
    }

    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: palette.error),
          const SizedBox(height: AppSpacing.s),
          Text(
            'We could not load rides',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _autocompleteField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    Widget? suffixIcon,
  }) {
    final palette = context.palette;

    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        return _locationSuggestionsFor(textEditingValue.text);
      },
      onSelected: (value) {
        controller.text = value;
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        if (textController.text != controller.text) {
          textController.value = TextEditingValue(
            text: controller.text,
            selection: TextSelection.collapsed(offset: controller.text.length),
          );
        }

        return TextField(
          controller: textController,
          focusNode: focusNode,
          onChanged: (value) {
            controller.text = value;
            if (label == 'Destination') {
              unawaited(_handleDestinationChanged(value));
            }
          },
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: iconColor),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: palette.input,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
    );
  }
}

class _RideResultCard extends StatefulWidget {
  const _RideResultCard({
    required this.ride,
    required this.onTap,
    this.isBestMatch = false,
  });

  final RidesEntity ride;
  final VoidCallback onTap;
  final bool isBestMatch;

  @override
  State<_RideResultCard> createState() => _RideResultCardState();
}

class _RideResultCardState extends State<_RideResultCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final borderColor = _hovered ? palette.secondary : palette.border;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _hovered ? 1.01 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: AppShadows.sm,
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isBestMatch) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: palette.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Best match',
                          style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                ],
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: palette.primary,
                      child: Text(
                        widget.ride.driverInitials,
                        style: TextStyle(
                          color: palette.primaryForeground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ride.driverName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.ride.driverRating.toStringAsFixed(1)} (${widget.ride.reviewCount})',
                                style: TextStyle(
                                  color: palette.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.ride.verifiedByUniversity) ...[
                                const SizedBox(width: AppSpacing.s),
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: palette.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: palette.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.ride.priceLabel,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Text(
                          'per seat',
                          style: TextStyle(
                            color: palette.textPrimary.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s),
                  decoration: BoxDecoration(
                    color: palette.input,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: palette.border.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Column(
                    children: [
                      _routeRow(
                        icon: Icons.trip_origin,
                        iconColor: palette.secondary,
                        text: widget.ride.origin,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      _routeRow(
                        icon: Icons.place_outlined,
                        iconColor: palette.primary,
                        text: widget.ride.destination,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        Icons.schedule_outlined,
                        widget.ride.departureLabel,
                        widget.ride.durationLabel,
                      ),
                    ),
                    Expanded(
                      child: _metric(
                        Icons.event_seat_outlined,
                        '${widget.ride.availableSeats}/${widget.ride.totalSeats}',
                        '${widget.ride.availableSeats} seats left',
                      ),
                    ),
                    Expanded(
                      child: _metric(
                        Icons.trending_up,
                        '${widget.ride.onTimeRate}%',
                        'on-time',
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

  Widget _metric(IconData icon, String strong, String detail) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: palette.textSecondary),
          const SizedBox(height: 4),
          Text(
            strong,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          Text(
            detail,
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _routeRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    final palette = context.palette;

    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Icon(Icons.arrow_forward, color: palette.textSecondary, size: 14),
      ],
    );
  }
}
