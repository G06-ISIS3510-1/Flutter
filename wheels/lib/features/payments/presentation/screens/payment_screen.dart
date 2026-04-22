import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/utils/app_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../auth/domain/entities/auth_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../rides/domain/entities/rides_entity.dart';
import '../../../rides/presentation/models/ride_listing.dart';
import '../../../rides/presentation/providers/rides_providers.dart';
import '../../domain/entities/payment_flow_status.dart';
import '../providers/payment_provider.dart';
import '../widgets/payment_status_banner.dart';
import 'checkout_webview_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({this.rideId, super.key});

  final String? rideId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  static const _quantity = 1;

  String? _observedRideId;
  String? _observedPassengerId;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(ridePaymentControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, _) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(error.toString().replaceFirst('Exception: ', '')),
              ),
            );
        },
      );
    });

    ref.listen<PaymentState>(paymentProvider, (previous, next) {
      final shouldOpenCheckout =
          next.status == PaymentFlowStatus.checkoutOpened &&
          next.checkoutUrl != null &&
          next.checkoutUrl != previous?.checkoutUrl;

      if (!shouldOpenCheckout) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CheckoutWebViewScreen(
              checkoutUrl: next.checkoutUrl!,
              rideId: next.rideId ?? _observedRideId ?? '',
              passengerId: next.passengerId ?? _observedPassengerId ?? '',
            ),
          ),
        );
      });
    });

    final fallbackRide = ref.watch(currentPassengerRideProvider).valueOrNull;
    final resolvedRideId = widget.rideId ?? fallbackRide?.id;
    final currentUser = ref.watch(authUserProvider);
    final resolvedPassengerId = currentUser?.uid;
    final bootstrapAsync = resolvedRideId == null
        ? const AsyncValue<RidePaymentBootstrapState>.data(
            RidePaymentBootstrapState(),
          )
        : ref.watch(
            ridePaymentBootstrapProvider(
              RidePaymentBootstrapRequest(
                rideId: resolvedRideId,
                passengerId: resolvedPassengerId,
              ),
            ),
          );
    final bootstrapData = bootstrapAsync.valueOrNull;

    if (resolvedRideId != null &&
        resolvedPassengerId != null &&
        (_observedRideId != resolvedRideId ||
            _observedPassengerId != resolvedPassengerId)) {
      _observedRideId = resolvedRideId;
      _observedPassengerId = resolvedPassengerId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref
            .read(paymentProvider.notifier)
            .observeRide(
              rideId: resolvedRideId,
              passengerId: resolvedPassengerId,
            );
      });
    }

    if (resolvedRideId == null) {
      return const AppScaffold(
        title: 'Ride payment',
        child: _MissingRideCard(
          message:
              'No ride is linked to your account yet. Apply to a ride first and then return here to pay.',
        ),
      );
    }

    final rideAsync = ref.watch(rideProvider(resolvedRideId));
    final effectiveRide = rideAsync.valueOrNull ?? bootstrapData?.ride;
    final effectivePassengerApplication = ref
            .watch(passengerRideApplicationProvider(resolvedRideId))
            .valueOrNull ??
        bootstrapData?.passengerApplication;

    return AppScaffold(
      title: 'Ride payment',
      child: Builder(
        builder: (context) {
          if (effectiveRide == null) {
            if (rideAsync.isLoading || bootstrapAsync.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final error = rideAsync.error ?? bootstrapData?.rideError;
            if (error != null) {
              return _MissingRideCard(message: error.toString());
            }

            return const _MissingRideCard(
              message:
                  'This ride is no longer available. Please go back to the dashboard and select another trip.',
            );
          }

          return _PaymentContent(
            ride: effectiveRide,
            quantity: _quantity,
            paymentState: ref.watch(paymentProvider),
            passengerApplication: effectivePassengerApplication,
            currentUser: currentUser,
            showConcurrentLoadNotice: bootstrapData?.hasAnyError ?? false,
            onGoDashboard: () => context.go(AppRoutes.dashboard),
            onStartCheckout: () {
              final user = ref.read(authUserProvider);
              if (user == null) {
                return;
              }

              ref
                  .read(paymentProvider.notifier)
                  .startCheckout(
                    rideId: effectiveRide.id,
                    title: _checkoutTitle(effectiveRide),
                    unitPrice: effectiveRide.pricePerSeat.toDouble(),
                    quantity: _quantity,
                    payerEmail: user.email,
                    userId: user.uid,
                    passengerId: user.uid,
                  );
            },
          );
        },
      ),
    );
  }

  static String _checkoutTitle(RidesEntity ride) {
    return 'Ride payment - ${ride.origin} to ${ride.destination}';
  }
}

class _PaymentContent extends ConsumerWidget {
  const _PaymentContent({
    required this.ride,
    required this.quantity,
    required this.paymentState,
    required this.passengerApplication,
    required this.currentUser,
    required this.showConcurrentLoadNotice,
    required this.onGoDashboard,
    required this.onStartCheckout,
  });

  final RidesEntity ride;
  final int quantity;
  final PaymentState paymentState;
  final RideApplicationEntity? passengerApplication;
  final AuthEntity? currentUser;
  final bool showConcurrentLoadNotice;
  final VoidCallback onGoDashboard;
  final VoidCallback onStartCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentRecord = paymentState.paymentRecord;
    final selectedPaymentMethod =
        (passengerApplication?.paymentMethod ==
                RidePassengerPaymentMethod.pendingSelection &&
            paymentRecord?.indicatesCardPaymentFlow == true)
        ? RidePassengerPaymentMethod.card
        : passengerApplication?.paymentMethod ??
              (ride.isManualTransferOnly
                  ? RidePassengerPaymentMethod.bankTransfer
                  : RidePassengerPaymentMethod.pendingSelection);
    final paymentMethodLocked =
        passengerApplication?.isPaymentLocked == true ||
        (paymentState.status == PaymentFlowStatus.approved &&
            selectedPaymentMethod == RidePassengerPaymentMethod.card);

    Future<void> selectPaymentMethod(
      RidePassengerPaymentMethod paymentMethod,
    ) async {
      final application = passengerApplication;
      if (application == null || currentUser == null || paymentMethodLocked) {
        return;
      }

      final currentMethod = application.paymentMethod;
      final currentStatus = application.paymentStatus;
      if (currentMethod == paymentMethod &&
          currentStatus == RidePassengerPaymentStatus.pending &&
          !application.isPaymentLocked) {
        return;
      }

      await ref
          .read(ridePaymentControllerProvider.notifier)
          .updatePassengerPaymentStatus(
            rideId: ride.id,
            passengerId: application.passengerId,
            paymentMethod: paymentMethod,
            paymentStatus: RidePassengerPaymentStatus.pending,
            isPaymentLocked: false,
            paymentStatusSource: 'passenger_selection',
          );
      ref.read(ridePaymentControllerProvider.notifier).clear();
    }

    if (ride.isManualTransferOnly ||
        selectedPaymentMethod == RidePassengerPaymentMethod.bankTransfer) {
      final manualStatus =
          passengerApplication?.paymentStatus ??
          RidePassengerPaymentStatus.pending;

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ManualTransferHeroCard(
              amount: ride.pricePerSeat.toDouble(),
              ride: ride,
              paymentStatus: manualStatus,
            ),
            if (ride.acceptsCardPayments) ...[
              const SizedBox(height: AppSpacing.l),
              _PaymentMethodSelectorCard(
                selectedMethod: selectedPaymentMethod,
                isLocked: paymentMethodLocked,
                onSelected: selectPaymentMethod,
              ),
            ],
            const SizedBox(height: AppSpacing.l),
            _ManualTransferStatusCard(
              paymentStatus: manualStatus,
              isLocked: passengerApplication?.isPaymentLocked ?? false,
            ),
            const SizedBox(height: AppSpacing.l),
            _DetailsCard(
              paymentState: paymentState,
              ride: ride,
              unitPrice: ride.pricePerSeat.toDouble(),
              quantity: quantity,
              paymentMethodLabel: selectedPaymentMethod.label,
              manualPaymentStatus: manualStatus.label,
            ),
            const SizedBox(height: AppSpacing.l),
            AppButton(
              label: 'Back to dashboard',
              onPressed: onGoDashboard,
              isPrimary: false,
            ),
          ],
        ),
      );
    }

    final isLoading = paymentState.status == PaymentFlowStatus.loading;
    final isApproved = paymentState.status == PaymentFlowStatus.approved;
    final isPending = paymentState.status == PaymentFlowStatus.pending;
    final isRejected = paymentState.status == PaymentFlowStatus.rejected;
    final isExpired = paymentState.status == PaymentFlowStatus.expired;
    final isError = paymentState.status == PaymentFlowStatus.error;
    final payerEmail = currentUser?.email ?? 'No email available';
    final userId = currentUser?.uid;
    final amount = ride.pricePerSeat.toDouble();
    final canStartCheckout =
        selectedPaymentMethod == RidePassengerPaymentMethod.card &&
        !isLoading &&
        !isApproved &&
        !isPending &&
        paymentState.status != PaymentFlowStatus.checkoutOpened &&
        !paymentMethodLocked &&
        !ride.isCompleted &&
        userId != null &&
        payerEmail.trim().isNotEmpty;
    final canRetryCheckout =
        (isRejected || isExpired || isError) &&
        selectedPaymentMethod == RidePassengerPaymentMethod.card &&
        !paymentMethodLocked &&
        !ride.isCompleted &&
        userId != null &&
        payerEmail.trim().isNotEmpty;

    if (selectedPaymentMethod == RidePassengerPaymentMethod.pendingSelection &&
        paymentMethodLocked) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LockedPaymentCard(
              title: 'Payment closed',
              message:
                  'This ride finished before a payment method was completed, so your payment was marked as unpaid and locked.',
            ),
            const SizedBox(height: AppSpacing.l),
            _DetailsCard(
              paymentState: paymentState,
              ride: ride,
              unitPrice: amount,
              quantity: quantity,
              paymentMethodLabel: selectedPaymentMethod.label,
              manualPaymentStatus: null,
            ),
            const SizedBox(height: AppSpacing.l),
            AppButton(
              label: 'Back to dashboard',
              onPressed: onGoDashboard,
              isPrimary: false,
            ),
          ],
        ),
      );
    }

    if (ride.acceptsCardPayments &&
        selectedPaymentMethod == RidePassengerPaymentMethod.pendingSelection) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MethodSelectionHeroCard(amount: amount, ride: ride),
            const SizedBox(height: AppSpacing.l),
            _PaymentMethodSelectorCard(
              selectedMethod: selectedPaymentMethod,
              isLocked: paymentMethodLocked,
              onSelected: selectPaymentMethod,
            ),
            const SizedBox(height: AppSpacing.l),
            _DetailsCard(
              paymentState: paymentState,
              ride: ride,
              unitPrice: amount,
              quantity: quantity,
              paymentMethodLabel: selectedPaymentMethod.label,
              manualPaymentStatus: null,
            ),
            const SizedBox(height: AppSpacing.l),
            AppButton(
              label: 'Back to dashboard',
              onPressed: onGoDashboard,
              isPrimary: false,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showConcurrentLoadNotice) ...[
            const _ConcurrentLoadNotice(),
            const SizedBox(height: AppSpacing.l),
          ],
          if (ride.acceptsCardPayments) ...[
            _PaymentMethodSelectorCard(
              selectedMethod: selectedPaymentMethod,
              isLocked: paymentMethodLocked,
              onSelected: selectPaymentMethod,
            ),
            const SizedBox(height: AppSpacing.l),
          ],
          const _MercadoPagoInfoCard(),
          const SizedBox(height: AppSpacing.l),
          _HeroCard(
            amount: amount,
            title: 'Ride payment - ${ride.origin} to ${ride.destination}',
            status: paymentState.status,
          ),
          const SizedBox(height: AppSpacing.l),
          PaymentStatusBanner(
            status: paymentState.status,
            message: paymentState.message,
          ),
          if (isLoading) ...[
            const SizedBox(height: AppSpacing.m),
            const LinearProgressIndicator(),
          ],
          if (paymentState.expiresAt != null &&
              (paymentState.status == PaymentFlowStatus.pending ||
                  paymentState.status == PaymentFlowStatus.checkoutOpened ||
                  paymentState.status == PaymentFlowStatus.loading)) ...[
            const SizedBox(height: AppSpacing.m),
            _PaymentWindowCard(expiresAt: paymentState.expiresAt!),
          ],
          const SizedBox(height: AppSpacing.l),
          _UserStatusCard(paymentState: paymentState),
          const SizedBox(height: AppSpacing.l),
          _DetailsCard(
            paymentState: paymentState,
            ride: ride,
            unitPrice: amount,
            quantity: quantity,
            paymentMethodLabel: selectedPaymentMethod.label,
            manualPaymentStatus: null,
          ),
          const SizedBox(height: AppSpacing.l),
          if (canStartCheckout && !canRetryCheckout)
            AppButton(
              label: 'Pay with Mercado Pago (PSE / Bancolombia)',
              onPressed: onStartCheckout,
            )
          else ...[
            if (canRetryCheckout) ...[
              AppButton(
                label: isExpired ? 'Start new checkout' : 'Try payment again',
                onPressed: onStartCheckout,
              ),
              const SizedBox(height: AppSpacing.s),
            ],
            AppButton(
              label: 'Back to dashboard',
              onPressed: onGoDashboard,
              isPrimary: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _MissingRideCard extends StatelessWidget {
  const _MissingRideCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'No ride ready for payment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConcurrentLoadNotice extends StatelessWidget {
  const _ConcurrentLoadNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sync_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              'Ride, passenger application, and payment-related status were loaded concurrently. If one secondary source fails, the payment flow still keeps the screen in a safe state.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualTransferHeroCard extends StatelessWidget {
  const _ManualTransferHeroCard({
    required this.amount,
    required this.ride,
    required this.paymentStatus,
  });

  final double amount;
  final RidesEntity ride;
  final RidePassengerPaymentStatus paymentStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF265D3A), Color(0xFF4B8E57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Direct bank transfer',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Send the payment directly to the driver outside the app and wait for their confirmation before the ride ends.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            AppFormatter.cop(amount),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Ride payment - ${ride.origin} to ${ride.destination}\nStatus: ${paymentStatus.label}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodSelectionHeroCard extends StatelessWidget {
  const _MethodSelectionHeroCard({required this.amount, required this.ride});

  final double amount;
  final RidesEntity ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A5C), Color(0xFF2D5A8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose how you will pay',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'This ride accepts card payments inside Wheels or direct transfer to the driver.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            AppFormatter.cop(amount),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            '${ride.origin} -> ${ride.destination}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodSelectorCard extends StatelessWidget {
  const _PaymentMethodSelectorCard({
    required this.selectedMethod,
    required this.isLocked,
    required this.onSelected,
  });

  final RidePassengerPaymentMethod selectedMethod;
  final bool isLocked;
  final ValueChanged<RidePassengerPaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment method',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            isLocked
                ? 'This payment is already closed and can no longer be changed.'
                : 'Choose the method you want to use for this ride.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Card in app'),
                selected: selectedMethod == RidePassengerPaymentMethod.card,
                onSelected: isLocked
                    ? null
                    : (_) => onSelected(RidePassengerPaymentMethod.card),
              ),
              ChoiceChip(
                label: const Text('Direct transfer'),
                selected:
                    selectedMethod == RidePassengerPaymentMethod.bankTransfer,
                onSelected: isLocked
                    ? null
                    : (_) =>
                          onSelected(RidePassengerPaymentMethod.bankTransfer),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MercadoPagoInfoCard extends StatelessWidget {
  const _MercadoPagoInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC6DCF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.info),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              'Mercado Pago checkout supports cards, PSE, and Bancolombia. Every checkout expires after 3 minutes if it is not approved.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentWindowCard extends StatefulWidget {
  const _PaymentWindowCard({required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<_PaymentWindowCard> createState() => _PaymentWindowCardState();
}

class _PaymentWindowCardState extends State<_PaymentWindowCard> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _remainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _remaining = _remainingTime();
      });
    });
  }

  @override
  void didUpdateWidget(covariant _PaymentWindowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      setState(() {
        _remaining = _remainingTime();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining <= Duration.zero;
    final minutes = _remaining.inMinutes.clamp(0, 99);
    final seconds = (_remaining.inSeconds % 60).clamp(0, 59);
    final countdown =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xFFFFEBEE) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired ? const Color(0xFFFFCDD2) : const Color(0xFFFFD9A6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isExpired ? Icons.timer_off_outlined : Icons.schedule_outlined,
            color: isExpired ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired
                      ? 'Checkout window reached the 3-minute limit'
                      : 'Checkout expires in $countdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isExpired
                      ? 'The app will update automatically when the backend marks this checkout as expired.'
                      : 'If approval does not arrive before this timer ends, the backend should mark the checkout as expired and Firestore will update the screen automatically.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Duration _remainingTime() {
    final remaining = widget.expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

class _LockedPaymentCard extends StatelessWidget {
  const _LockedPaymentCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ManualTransferStatusCard extends StatelessWidget {
  const _ManualTransferStatusCard({
    required this.paymentStatus,
    required this.isLocked,
  });

  final RidePassengerPaymentStatus paymentStatus;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final title = switch (paymentStatus) {
      RidePassengerPaymentStatus.paid => 'Payment confirmed by driver',
      RidePassengerPaymentStatus.unpaid => 'Payment marked as unpaid',
      RidePassengerPaymentStatus.pending => 'Waiting for driver confirmation',
    };
    final message = switch (paymentStatus) {
      RidePassengerPaymentStatus.paid =>
        'The driver has confirmed your transfer. No further action is needed.',
      RidePassengerPaymentStatus.unpaid =>
        'The driver still shows this ride as unpaid. Coordinate the transfer directly before the ride ends.',
      RidePassengerPaymentStatus.pending =>
        'This ride uses direct bank transfer. Complete the transfer with the driver and they will mark it as paid or unpaid before finishing the ride.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (isLocked) ...[
            const SizedBox(height: AppSpacing.s),
            const Text(
              'This confirmation is locked.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.amount,
    required this.title,
    required this.status,
  });

  final double amount;
  final String title;
  final PaymentFlowStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _heroColors(status),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _heroTitle(status),
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            _heroSubtitle(status),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            AppFormatter.cop(amount),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _heroColors(PaymentFlowStatus status) {
    switch (status) {
      case PaymentFlowStatus.approved:
        return const [Color(0xFF0A8F68), Color(0xFF13B97A)];
      case PaymentFlowStatus.pending:
        return const [Color(0xFFC77700), Color(0xFFFFA726)];
      case PaymentFlowStatus.expired:
        return const [Color(0xFF7C2D12), Color(0xFFD97706)];
      case PaymentFlowStatus.rejected:
      case PaymentFlowStatus.error:
        return const [Color(0xFF9F1C1C), Color(0xFFE05252)];
      case PaymentFlowStatus.idle:
      case PaymentFlowStatus.loading:
      case PaymentFlowStatus.checkoutOpened:
        return const [AppColors.primary, AppColors.primaryLight];
    }
  }

  String _heroTitle(PaymentFlowStatus status) {
    switch (status) {
      case PaymentFlowStatus.approved:
        return 'Ride paid successfully';
      case PaymentFlowStatus.pending:
        return 'We are verifying your payment';
      case PaymentFlowStatus.expired:
        return 'Payment session expired';
      case PaymentFlowStatus.rejected:
        return 'Payment failed';
      case PaymentFlowStatus.error:
        return 'Payment status unavailable';
      case PaymentFlowStatus.idle:
      case PaymentFlowStatus.loading:
      case PaymentFlowStatus.checkoutOpened:
        return 'Mercado Pago checkout';
    }
  }

  String _heroSubtitle(PaymentFlowStatus status) {
    switch (status) {
      case PaymentFlowStatus.approved:
        return 'Your ride is already paid. You do not need to pay again.';
      case PaymentFlowStatus.pending:
        return 'This screen listens to Firestore updates from the backend until Mercado Pago returns a final result.';
      case PaymentFlowStatus.expired:
        return 'The checkout reached the 3-minute limit without approval. Start a new payment to continue.';
      case PaymentFlowStatus.rejected:
        return 'The payment could not be completed. You can go back or try again.';
      case PaymentFlowStatus.error:
        return 'We could not confirm the payment yet. Wait for Firestore updates or try again.';
      case PaymentFlowStatus.idle:
      case PaymentFlowStatus.loading:
      case PaymentFlowStatus.checkoutOpened:
        return 'The checkout opens inside the app with Mercado Pago, including PSE and Bancolombia options, and expires after 3 minutes.';
    }
  }
}

class _UserStatusCard extends StatelessWidget {
  const _UserStatusCard({required this.paymentState});

  final PaymentState paymentState;

  @override
  Widget build(BuildContext context) {
    final status = paymentState.status;
    if (status == PaymentFlowStatus.idle ||
        status == PaymentFlowStatus.loading ||
        status == PaymentFlowStatus.checkoutOpened) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _userTitle(status),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            _userDescription(status, paymentState.message),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _userTitle(PaymentFlowStatus status) {
    switch (status) {
      case PaymentFlowStatus.approved:
        return 'Payment confirmed';
      case PaymentFlowStatus.pending:
        return 'Payment verification in progress';
      case PaymentFlowStatus.expired:
        return 'Payment window expired';
      case PaymentFlowStatus.rejected:
        return 'Payment was not completed';
      case PaymentFlowStatus.error:
        return 'We could not validate the payment';
      case PaymentFlowStatus.idle:
      case PaymentFlowStatus.loading:
      case PaymentFlowStatus.checkoutOpened:
        return '';
    }
  }

  String _userDescription(PaymentFlowStatus status, String? message) {
    if (message != null && message.isNotEmpty) {
      return message;
    }
    switch (status) {
      case PaymentFlowStatus.approved:
        return 'Everything is ready. You can go back to your dashboard.';
      case PaymentFlowStatus.pending:
        return 'Please wait while the backend writes the latest payment result to Firestore.';
      case PaymentFlowStatus.expired:
        return 'The checkout expired after 3 minutes. Start a new payment if you still need this ride.';
      case PaymentFlowStatus.rejected:
        return 'You can return to your ride or try the payment again.';
      case PaymentFlowStatus.error:
        return 'Wait for Firestore updates or try starting checkout again.';
      case PaymentFlowStatus.idle:
      case PaymentFlowStatus.loading:
      case PaymentFlowStatus.checkoutOpened:
        return '';
    }
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.paymentState,
    required this.ride,
    required this.unitPrice,
    required this.quantity,
    required this.paymentMethodLabel,
    required this.manualPaymentStatus,
  });

  final PaymentState paymentState;
  final RidesEntity ride;
  final double unitPrice;
  final int quantity;
  final String paymentMethodLabel;
  final String? manualPaymentStatus;

  @override
  Widget build(BuildContext context) {
    final totalAmount = unitPrice * quantity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ride summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total to pay',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppFormatter.cop(totalAmount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  quantity == 1
                      ? 'Payment for 1 seat on this ride.'
                      : 'Payment for $quantity seats on this ride.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          _DetailRow(label: 'Driver', value: ride.driverName),
          _DetailRow(
            label: 'Route',
            value: '${ride.origin} -> ${ride.destination}',
          ),
          _DetailRow(label: 'Date', value: ride.dateLabel),
          _DetailRow(label: 'Departure', value: ride.departureLabel),
          _DetailRow(label: 'Payment method', value: paymentMethodLabel),
          _DetailRow(
            label: quantity == 1 ? 'Seat' : 'Seats',
            value: quantity.toString(),
          ),
          _DetailRow(
            label: 'Price per seat',
            value: AppFormatter.cop(unitPrice),
          ),
          _DetailRow(
            label: 'Current status',
            value: _friendlyStatusLabel(paymentState.status),
          ),
          if (manualPaymentStatus != null)
            _DetailRow(
              label: 'Driver confirmation',
              value: manualPaymentStatus!,
            ),
        ],
      ),
    );
  }

  String _friendlyStatusLabel(PaymentFlowStatus status) {
    switch (status) {
      case PaymentFlowStatus.idle:
        return 'Ready to pay';
      case PaymentFlowStatus.loading:
      case PaymentFlowStatus.checkoutOpened:
        return 'Opening checkout';
      case PaymentFlowStatus.pending:
        return 'Waiting for confirmation';
      case PaymentFlowStatus.approved:
        return 'Payment approved';
      case PaymentFlowStatus.rejected:
        return 'Payment failed';
      case PaymentFlowStatus.expired:
        return 'Payment expired';
      case PaymentFlowStatus.error:
        return 'Status unavailable';
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
