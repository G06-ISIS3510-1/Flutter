import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/services/current_location_service.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/utils/app_formatter.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_gradient_header.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../domain/entities/rides_entity.dart';
import '../providers/rides_providers.dart';

/// Driver form used to publish a ride with schedule, seats, route, and payment details.
class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _currentLocationService = const CurrentLocationService();
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
  RidePaymentOption _paymentOption = RidePaymentOption.card;
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
  void initState() {
    super.initState();
    // Pre-fill the pickup field when GPS resolution succeeds on first load.
    Future.microtask(_prefillOriginWithCurrentLocation);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _prefillOriginWithCurrentLocation() async {
    if (_origin.trim().isNotEmpty) {
      return;
    }

    try {
      final address = await _currentLocationService.getCurrentAddress();
      if (!mounted) {
        return;
      }

      _originFieldKey.currentState?.didChange(address);
      setState(() {
        _origin = address;
        _currentLocationSuggestion = address;
        _originLocationError = null;
      });
    } catch (_) {
      // Keep the field empty if the app cannot resolve the location on load.
    }
  }

  Future<void> _useCurrentLocationAsOrigin() async {
    setState(() {
      _isResolvingOriginFromGps = true;
      _originLocationError = null;
    });

    try {
      final address = await _currentLocationService.getCurrentAddress();

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

  List<String> _locationSuggestionsFor(String query) {
    // Blend static campus shortcuts with the latest resolved GPS suggestion.
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

  double get _grossPerSeat => _pricePerSeat.toDouble();
  double get _estimatedGrossIfFull => _availableSeats * _grossPerSeat;
  double get _estimatedCardFeePerSeat =>
      AppFormatter.mercadoPagoCardFee(_grossPerSeat);
  double get _estimatedNetPerCardSeat =>
      AppFormatter.mercadoPagoCardNet(_grossPerSeat);
  double get _estimatedCardFeesIfAllSeatsPayByCard =>
      _availableSeats * _estimatedCardFeePerSeat;
  double get _estimatedNetIfAllSeatsPayByCard =>
      _availableSeats * _estimatedNetPerCardSeat;

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

    // Drivers should only publish future departures to keep listings coherent.
    if (!departureAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Departure time must be in the future.')),
      );
      return;
    }

    final rideId = await ref
        .read(createRideControllerProvider.notifier)
        .createRide(
          driverId: currentUser.uid,
          driverName: currentUser.fullName,
          driverEmail: currentUser.email,
          origin: _origin.trim(),
          destination: _destination.trim(),
          departureAt: departureAt,
          estimatedDurationMinutes: _durationMinutes,
          totalSeats: _availableSeats,
          pricePerSeat: _pricePerSeat,
          paymentOption: _paymentOption,
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
    final palette = context.palette;

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
      backgroundColor: context.palette.background,
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
        color: context.palette.card,
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
                    backgroundColor: palette.accent,
                    foregroundColor: palette.accentForeground,
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
                              icon: Icon(
                                Icons.near_me_outlined,
                                color: palette.secondary,
                              ),
                            ),
                    ),
                    if (_originLocationError != null) ...[
                      const SizedBox(height: AppSpacing.s),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: palette.error,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _originLocationError!,
                              style: TextStyle(
                                color: palette.error,
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
                        suffixIcon: Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'min',
                            style: TextStyle(
                              color: palette.textSecondary,
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
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: palette.primary,
                              ),
                            ),
                            Text(
                              'seats available',
                              style: TextStyle(
                                color: palette.textSecondary,
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
                    Text(
                      'Choose what payment methods this ride will allow.',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _PaymentOptionTile(
                      title: 'Card plus transfer',
                      subtitle:
                          'If a rider pays by card, you keep about ${AppFormatter.cop(_estimatedNetPerCardSeat)} per seat.',
                      helper:
                          'Passengers can pay in-app with Mercado Pago or transfer directly to you. Card fees follow 3.29% + VAT on that fee + COP 952 per payment.',
                      icon: Icons.credit_card_rounded,
                      isSelected: _paymentOption == RidePaymentOption.card,
                      onTap: () {
                        setState(() {
                          _paymentOption = RidePaymentOption.card;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.s),
                    _PaymentOptionTile(
                      title: 'Transfer only',
                      subtitle:
                          'The rider pays you directly outside the platform.',
                      helper:
                          'Use this if you prefer manual payment coordination.',
                      icon: Icons.account_balance_rounded,
                      isSelected:
                          _paymentOption == RidePaymentOption.bankTransfer,
                      onTap: () {
                        setState(() {
                          _paymentOption = RidePaymentOption.bankTransfer;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: palette.input,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: palette.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _paymentOption == RidePaymentOption.card
                                ? 'Estimated take-home per card-paid seat'
                                : 'Estimated amount you receive per seat',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            AppFormatter.cop(
                              _paymentOption == RidePaymentOption.card
                                  ? _estimatedNetPerCardSeat
                                  : _grossPerSeat,
                            ),
                            style: TextStyle(
                              color: palette.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (_paymentOption == RidePaymentOption.card) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Seat price: ${AppFormatter.cop(_grossPerSeat)}. Estimated Mercado Pago fee per payment: ${AppFormatter.cop(_estimatedCardFeePerSeat)}.',
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'If all $_availableSeats seats are paid by card, you keep about ${AppFormatter.cop(_estimatedNetIfAllSeatsPayByCard)} net from ${AppFormatter.cop(_estimatedGrossIfFull)} gross.',
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'With direct transfer, you keep the full ${AppFormatter.cop(_estimatedGrossIfFull)} if all $_availableSeats seats are sold.',
                              style: TextStyle(
                                color: palette.textSecondary,
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
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: palette.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: palette.card,
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
        final palette = context.palette;
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
                    color: palette.card,
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
    final palette = context.palette;

    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
        suffixIcon: Icon(trailing, color: palette.textSecondary),
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
    final palette = context.palette;

    return InputDecoration(
      label: label == null
          ? null
          : _FieldLabel(icon: icon ?? Icons.info_outline, text: label),
      hintText: hint,
      hintStyle: TextStyle(color: palette.textSecondary),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: palette.input,
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
        borderSide: BorderSide(color: palette.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: palette.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: palette.error),
      ),
    );
  }

  Widget _seatControlButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Ink(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onTap == null ? palette.surfaceMuted : palette.secondarySoft,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, color: palette.textSecondary),
      ),
    );
  }

  Widget _estimatedEarningsCard() {
    final palette = context.palette;
    // The summary updates live so drivers understand card fees before posting.
    final headlineAmount = _paymentOption == RidePaymentOption.card
        ? _estimatedNetIfAllSeatsPayByCard
        : _estimatedGrossIfFull;
    final title = _paymentOption == RidePaymentOption.card
        ? 'Estimated take-home if all riders pay by card'
        : 'Estimated earnings';
    final subtitle = _paymentOption == RidePaymentOption.card
        ? 'Gross sales ${AppFormatter.cop(_estimatedGrossIfFull)}. Estimated card fees ${AppFormatter.cop(_estimatedCardFeesIfAllSeatsPayByCard)}.'
        : '$_availableSeats seats x ${AppFormatter.cop(_grossPerSeat)} each';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.m,
      ),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.primaryForeground,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppFormatter.cop(headlineAmount),
                  style: TextStyle(
                    color: palette.primaryForeground,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: palette.primaryForeground,
                    fontSize: 13,
                  ),
                ),
                if (_paymentOption == RidePaymentOption.card) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Direct transfers still keep the full ${AppFormatter.cop(_estimatedGrossIfFull)}.',
                    style: TextStyle(
                      color: palette.primaryForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: palette.primaryForeground.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.attach_money,
              color: palette.primaryForeground,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Icon(icon, size: 18, color: palette.secondary),
        const SizedBox(width: AppSpacing.s),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textPrimary,
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
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: isSelected ? palette.secondarySoft : palette.card,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? palette.secondary : palette.border,
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
                    ? palette.secondary
                    : palette.secondarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? palette.primaryForeground
                    : palette.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: palette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    helper,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? palette.secondary : palette.border,
            ),
          ],
        ),
      ),
    );
  }
}
