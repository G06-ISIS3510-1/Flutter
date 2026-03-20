import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_gradient_header.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../mock/rides_mock_data.dart';
import '../models/ride_listing.dart';

class RidesSearchScreen extends ConsumerStatefulWidget {
  const RidesSearchScreen({super.key});

  @override
  ConsumerState<RidesSearchScreen> createState() => _RidesSearchScreenState();
}

class _RidesSearchScreenState extends ConsumerState<RidesSearchScreen> {
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

  DateTime _selectedDate = DateTime.now();
  RideSortOption _sort = RideSortOption.earliest;
  List<RideListing> _results = <RideListing>[];

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_selectedDate);
    _runSearch();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    super.dispose();
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
      _dateController.text = _formatDate(_selectedDate);
    });
    _runSearch();
  }

  void _runSearch() {
    final source = buildMockRides(_selectedDate);
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final originQuery = _originController.text.trim().toLowerCase();
    final destinationQuery = _destinationController.text.trim().toLowerCase();

    final filtered = source.where((ride) {
      final rideDay = DateTime(
        ride.departureDateTime.year,
        ride.departureDateTime.month,
        ride.departureDateTime.day,
      );
      if (rideDay != selectedDay) {
        return false;
      }
      final originMatch =
          originQuery.isEmpty ||
          ride.origin.toLowerCase().contains(originQuery);
      final destinationMatch =
          destinationQuery.isEmpty ||
          ride.destination.toLowerCase().contains(destinationQuery);
      return originMatch && destinationMatch;
    }).toList();

    filtered.sort(
      (a, b) => switch (_sort) {
        RideSortOption.earliest => a.departureDateTime.compareTo(
          b.departureDateTime,
        ),
        RideSortOption.cheapest => a.pricePerSeat.compareTo(b.pricePerSeat),
        RideSortOption.highestRated => b.rating.compareTo(a.rating),
      },
    );

    setState(() {
      _results = filtered;
    });
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final role = ref.watch(currentUserRoleProvider);

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
            const SizedBox(height: AppSpacing.l),
            _sectionTitle('Available Drivers', '${_results.length} rides'),
            const SizedBox(height: AppSpacing.s),
            if (_results.isEmpty) _emptyState(),
            for (final ride in _results) ...[
              _RideResultCard(
                ride: ride,
                onTap: () => context.go(AppRoutes.rideDetailsById(ride.id)),
              ),
              const SizedBox(height: AppSpacing.m),
            ],
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
          ),
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
            child: ElevatedButton.icon(
              onPressed: _runSearch,
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
                      _runSearch();
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

  Widget _emptyState() {
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
            'Try changing origin, destination or date.',
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
  }) {
    final palette = context.palette;
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase().trim();
        if (query.isEmpty) {
          return _campusLocations;
        }
        return _campusLocations.where(
          (location) => location.toLowerCase().contains(query),
        );
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
          onChanged: (value) => controller.text = value,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: iconColor),
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
  const _RideResultCard({required this.ride, required this.onTap});

  final RideListing ride;
  final VoidCallback onTap;

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
                                '${widget.ride.rating} (${widget.ride.reviewCount})',
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
                    border: Border.all(color: palette.border.withValues(alpha: 0.65)),
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
                        '${widget.ride.seatsLeft}/4',
                        '${widget.ride.seatsLeft} seats left',
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
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
            ),
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
        Icon(
          Icons.arrow_forward,
          color: palette.textSecondary,
          size: 14,
        ),
      ],
    );
  }
}
