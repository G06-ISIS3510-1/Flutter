import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
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
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _availableSeats = 3;
  String _origin = '';
  String _destination = '';

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
    _priceController.dispose();
    super.dispose();
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

  double get _pricePerSeat {
    final parsed = double.tryParse(_priceController.text.trim());
    return parsed ?? 0;
  }

  double get _estimatedEarnings => _availableSeats * _pricePerSeat;

  void _publishRide() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final summary =
        '$_origin -> $_destination | $_availableSeats seats | \$${_priceController.text.trim()}';
    ref.read(publishedRideSummaryProvider.notifier).state = summary;
    ref.read(activeRideCountProvider.notifier).state = 1;

    context.go(AppRoutes.activeRide);
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.muted,
      body: SafeArea(
        child: Column(
          children: [
            Column(
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
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  primary: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    0,
                    AppSpacing.m,
                    AppSpacing.m,
                  ),
                  children: [
                    _sectionCard(
                      title: 'Route Details',
                      child: Column(
                        children: [
                          _locationAutocompleteField(
                            label: 'Pickup Location',
                            hint: 'e.g. Campus Uniandes - Main Gate',
                            icon: Icons.location_pin,
                            onChanged: (value) => _origin = value,
                            validatorText: 'Pickup location is required.',
                          ),
                          const SizedBox(height: AppSpacing.m),
                          _locationAutocompleteField(
                            label: 'Destination',
                            hint: 'e.g. Centro Comercial Andino',
                            icon: Icons.place_outlined,
                            onChanged: (value) => _destination = value,
                            validatorText: 'Destination is required.',
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
                              decimal: true,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}$'),
                              ),
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
                              final parsed = double.tryParse(value);
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
                      title: 'Additional Information (Optional)',
                      child: TextFormField(
                        controller: _notesController,
                        minLines: 4,
                        maxLines: 5,
                        decoration: _inputDecoration(
                          label: 'Notes',
                          hint:
                              'Only women, pets allowed, stops along the way...',
                          icon: Icons.notes_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.card,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.s,
          AppSpacing.m,
          AppSpacing.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _publishRide,
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
            const SizedBox(height: AppSpacing.s),
            AppBottomNav(currentTab: AppBottomNavTab.middle, role: role),
          ],
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
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    required String validatorText,
  }) {
    return FormField<String>(
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
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.isEmpty) {
                  return _campusLocations;
                }
                return _campusLocations.where(
                  (option) => option.toLowerCase().contains(query),
                );
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
                '$_availableSeats seats x \$${_pricePerSeat.toStringAsFixed(0)} each',
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
        Text(
          text,
          style: const TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
