import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_gradient_header.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/rides_providers.dart';

class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originFieldKey = GlobalKey<FormFieldState<String>>();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _priceController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _availableSeats = 3;
  String _origin = '';
  String _destination = '';
  DriverPaymentOption _paymentOption = DriverPaymentOption.card;
  bool _isResolvingOriginFromGps = false;
  String? _originLocationError;
  String? _currentLocationSuggestion;

  static const List<String> _campusLocations = <String>[
    'Campus Uniandes - Main Gate',
    'Campus Uniandes - ML Building',
    'Centro Comercial Andino',
    'Plazoleta de Arquitectura',
    'Biblioteca General',
    'Parqueadero Principal',
    'Porteria Calle 19A',
    'Universidad Nacional - Entrada 45',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocationAsOrigin() async {
    setState(() {
      _isResolvingOriginFromGps = true;
      _originLocationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled on this device.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final address = await _reverseGeocodePosition(position);

      _originFieldKey.currentState?.didChange(address);

      if (!mounted) {
        return;
      }

      setState(() {
        _origin = address;
        _currentLocationSuggestion = address;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup location updated from GPS.')),
      );
    } catch (error, stackTrace) {
      debugPrint('GPS origin error: $error');
      debugPrintStack(stackTrace: stackTrace);

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

  Future<String> _reverseGeocodePosition(Position position) async {
    final fallbackAddress =
        'Current location (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return fallbackAddress;
      }

      final placemark = placemarks.first;
      final parts =
          <String?>[
                placemark.street,
                placemark.subLocality,
                placemark.locality,
                placemark.administrativeArea,
                placemark.country,
              ]
              .whereType<String>()
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty)
              .toList();

      if (parts.isEmpty) {
        return fallbackAddress;
      }

      return parts.toSet().join(', ');
    } catch (error, stackTrace) {
      debugPrint('Reverse geocoding failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      return fallbackAddress;
    }
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

    return uniqueSuggestions
        .where((option) => option.toLowerCase().contains(normalizedQuery))
        .toList();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _selectedDate ?? now,
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
      _dateController.text = _formatDate(pickedDate);
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = pickedTime;
      _timeController.text = _formatTime(pickedTime);
    });
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int get _durationMinutes {
    return int.tryParse(_durationController.text.trim()) ?? 0;
  }

  int get _pricePerSeat {
    final parsed = int.tryParse(_priceController.text.trim());
    return parsed ?? 0;
  }

  double get _estimatedEarnings => _availableSeats * _pricePerSeat.toDouble();
  double get _platformFixedFee => 800;
  double get _platformPercentageFee => _estimatedEarnings * 0.033;
  double get _estimatedNetAfterPlatformFee =>
      _paymentOption == DriverPaymentOption.card
      ? (_estimatedEarnings - _platformFixedFee - _platformPercentageFee).clamp(
          0,
          double.infinity,
        )
      : _estimatedEarnings;

  Future<void> _publishRide() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final currentUser = ref.read(authUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in again before publishing your ride.'),
        ),
      );
      return;
    }

    final selectedDate = _selectedDate;
    final selectedTime = _selectedTime;
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both date and departure time.')),
      );
      return;
    }

    final departureAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (!departureAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Departure time must be in the future.'),
        ),
      );
      return;
    }

    final rideId = await ref.read(createRideControllerProvider.notifier).createRide(
      driverId: currentUser.uid,
      driverName: currentUser.fullName,
      driverEmail: currentUser.email,
      origin: _origin.trim(),
      destination: _destination.trim(),
      departureAt: departureAt,
      estimatedDurationMinutes: _durationMinutes,
      totalSeats: _availableSeats,
      pricePerSeat: _pricePerSeat,
      notes: _notesController.text.trim(),
    );

    if (!mounted || rideId == null) {
      return;
    }

    ref.read(createRideControllerProvider.notifier).clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ride published successfully.')),
    );
    context.go(AppRoutes.activeRideById(rideId));
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    final createRideState = ref.watch(createRideControllerProvider);

    ref.listen<AsyncValue<String?>>(createRideControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, _) {
          final message = error is Exception
              ? error.toString().replaceFirst('Exception: ', '')
              : 'We could not publish your ride right now.';
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    return AppScaffold(
      title: 'Create Ride',
      showAppBar: false,
      backgroundColor: AppColors.muted,
      scrollableHeader: Column(
        children: [
          AppGradientHeader(
            title: 'Create a Ride',
            subtitle: 'Publish your ride and earn money',
            onBack: () => context.go(AppRoutes.dashboard),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.l,
            ),
            child: _estimatedEarningsCard(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.card,
        padding: const EdgeInsets.only(top: AppSpacing.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: createRideState.isLoading ? null : _publishRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentForeground,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  label: const Text(
                    'Publish Ride',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            AppBottomNav(currentTab: AppBottomNavTab.middle, role: role),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          0,
          AppSpacing.m,
          AppSpacing.m,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _sectionCard(
                title: 'Route Details',
                child: Column(
                  children: [
                    _locationAutocompleteField(
                      fieldKey: _originFieldKey,
                      label: 'Pickup Location',
                      hint: 'e.g. Campus Uniandes - Main Gate',
                      icon: Icons.location_pin,
                      onChanged: (value) => _origin = value,
                      validatorText: 'Pickup location is required.',
                      suggestions: _locationSuggestionsFor,
                      suffixIcon: _isResolvingOriginFromGps
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Use current location',
                              onPressed: _useCurrentLocationAsOrigin,
                              icon: const Icon(
                                Icons.my_location,
                                color: AppColors.secondary,
                              ),
                            ),
                    ),
                    if (_originLocationError != null) ...[
                      const SizedBox(height: AppSpacing.s),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _originLocationError!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.m),
                    _locationAutocompleteField(
                      label: 'Destination',
                      hint: 'e.g. Centro Comercial Andino',
                      icon: Icons.place_outlined,
                      onChanged: (value) => _destination = value,
                      validatorText: 'Destination is required.',
                      suggestions: _locationSuggestionsFor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              _sectionCard(
                title: 'Schedule',
                child: Column(
                  children: [
                    _readOnlyField(
                      controller: _dateController,
                      label: 'Date',
                      hint: 'dd/mm/yyyy',
                      icon: Icons.calendar_month_outlined,
                      trailing: Icons.edit_calendar_outlined,
                      onTap: _pickDate,
                      validatorText: 'Date is required.',
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _readOnlyField(
                      controller: _timeController,
                      label: 'Departure Time',
                      hint: '--:--',
                      icon: Icons.schedule_outlined,
                      trailing: Icons.watch_later_outlined,
                      onTap: _pickTime,
                      validatorText: 'Departure time is required.',
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: _inputDecoration(
                        label: 'Estimated Duration',
                        hint: '30',
                        icon: Icons.timer_outlined,
                        suffixIcon: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'min',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Estimated duration is required.';
                        }
                        final parsed = int.tryParse(value);
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid duration.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              _sectionCard(
                title: 'Capacity & Pricing',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(
                      icon: Icons.groups_outlined,
                      text: 'Available Seats',
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _seatControlButton(
                          icon: Icons.remove,
                          onTap: _availableSeats > 1
                              ? () => setState(() {
                                  _availableSeats -= 1;
                                })
                              : null,
                        ),
                        Column(
                          children: [
                            Text(
                              '$_availableSeats',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(
                              'seats available',
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        _seatControlButton(
                          icon: Icons.add,
                          onTap: _availableSeats < 4
                              ? () => setState(() {
                                  _availableSeats += 1;
                                })
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: _inputDecoration(
                        label: 'Price per Seat',
                        hint: '3500',
                        icon: Icons.attach_money,
                        prefixText: '\$ ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Price per seat is required.';
                        }
                        final parsed = int.tryParse(value);
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid price.';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              _sectionCard(
                title: 'Payment Options',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose how riders will pay for this trip.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _PaymentOptionTile(
                      title: 'Accept card payments',
                      subtitle:
                          'Wheels keeps \$800 COP + 3.3% of the purchase.',
                      helper:
                          'Recommended if you want riders to pay inside the app with Mercado Pago.',
                      icon: Icons.credit_card_rounded,
                      isSelected: _paymentOption == DriverPaymentOption.card,
                      onTap: () {
                        setState(() {
                          _paymentOption = DriverPaymentOption.card;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.s),
                    _PaymentOptionTile(
                      title: 'Direct bank transfer',
                      subtitle:
                          'The rider pays you directly outside the platform.',
                      helper:
                          'Use this if you prefer manual payment coordination.',
                      icon: Icons.account_balance_rounded,
                      isSelected:
                          _paymentOption == DriverPaymentOption.bankTransfer,
                      onTap: () {
                        setState(() {
                          _paymentOption = DriverPaymentOption.bankTransfer;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: AppColors.input,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _paymentOption == DriverPaymentOption.card
                                ? 'Estimated net after platform fee'
                                : 'Estimated amount you receive',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '\$${_estimatedNetAfterPlatformFee.toStringAsFixed(0)} COP',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (_paymentOption == DriverPaymentOption.card) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Gross: \$${_estimatedEarnings.toStringAsFixed(0)} | Fee: \$${(_platformFixedFee + _platformPercentageFee).toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              _sectionCard(
                title: 'Additional Information (Optional)',
                child: TextFormField(
                  controller: _notesController,
                  minLines: 4,
                  maxLines: 5,
                  decoration: _inputDecoration(
                    label: 'Notes',
                    hint: 'Only women, pets allowed, stops along the way...',
                    icon: Icons.notes_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.sm,
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _locationAutocompleteField({
    GlobalKey<FormFieldState<String>>? fieldKey,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    required String validatorText,
    required List<String> Function(String query) suggestions,
    Widget? suffixIcon,
  }) {
    return FormField<String>(
      key: fieldKey,
      initialValue: '',
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorText;
        }
        return null;
      },
      builder: (field) {
        final currentValue = field.value ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel(icon: icon, text: label),
            const SizedBox(height: AppSpacing.s),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: currentValue),
              optionsBuilder: (textEditingValue) {
                return suggestions(textEditingValue.text);
              },
              onSelected: (value) {
                field.didChange(value);
                onChanged(value);
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    color: AppColors.card,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 180,
                        minWidth: 260,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.m,
                                vertical: AppSpacing.s,
                              ),
                              child: Text(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    if (controller.text != currentValue) {
                      controller.value = TextEditingValue(
                        text: currentValue,
                        selection: TextSelection.collapsed(
                          offset: currentValue.length,
                        ),
                      );
                    }
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: _inputDecoration(
                        label: null,
                        hint: hint,
                        icon: null,
                        errorText: field.errorText,
                        suffixIcon: suffixIcon,
                      ),
                      onChanged: (value) {
                        field.didChange(value);
                        onChanged(value);
                      },
                    );
                  },
            ),
          ],
        );
      },
    );
  }

  Widget _readOnlyField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required IconData trailing,
    required VoidCallback onTap,
    required String validatorText,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
        suffixIcon: Icon(trailing, color: AppColors.textSecondary),
      ),
      onTap: onTap,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorText;
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String? label,
    required String hint,
    required IconData? icon,
    Widget? suffixIcon,
    String? prefixText,
    String? errorText,
  }) {
    return InputDecoration(
      label: label == null
          ? null
          : _FieldLabel(icon: icon ?? Icons.info_outline, text: label),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.mutedForeground),
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: AppColors.input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Widget _seatControlButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Ink(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.muted : AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.mutedForeground),
      ),
    );
  }

  Widget _estimatedEarningsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.m,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimated Earnings',
                style: TextStyle(
                  color: AppColors.primaryForeground,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '\$${_estimatedEarnings.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.primaryForeground,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$_availableSeats seats x \$$_pricePerSeat each',
                style: const TextStyle(
                  color: AppColors.primaryForeground,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryForeground.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.attach_money,
              color: AppColors.primaryForeground,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

enum DriverPaymentOption { card, bankTransfer }

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.s),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.title,
    required this.subtitle,
    required this.helper,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String helper;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF2FD) : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary
                    : AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryForeground
                    : AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    helper,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.secondary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}
