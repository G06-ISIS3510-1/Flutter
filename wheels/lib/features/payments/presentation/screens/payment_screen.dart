import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
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

  @override
  Widget build(BuildContext context) {
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
            ),
          ),
        );
      });
    });

    final fallbackRide = ref.watch(currentPassengerRideProvider).valueOrNull;
    final resolvedRideId = widget.rideId ?? fallbackRide?.id;

    if (resolvedRideId != null && _observedRideId != resolvedRideId) {
      _observedRideId = resolvedRideId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(paymentProvider.notifier).observeRide(resolvedRideId);
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

    return AppScaffold(
      title: 'Ride payment',
      child: rideAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MissingRideCard(message: error.toString()),
        data: (ride) {
          if (ride == null) {
            return const _MissingRideCard(
              message:
                  'This ride is no longer available. Please go back to the dashboard and select another trip.',
            );
          }

          return _PaymentContent(
            ride: ride,
            quantity: _quantity,
            paymentState: ref.watch(paymentProvider),
            currentUser: ref.watch(authUserProvider),
            onBack: () => _goBack(context),
            onStartCheckout: () {
              final user = ref.read(authUserProvider);
              if (user == null) {
                return;
              }

              ref.read(paymentProvider.notifier).startCheckout(
                    rideId: ride.id,
                    title: _checkoutTitle(ride),
                    unitPrice: ride.pricePerSeat.toDouble(),
                    quantity: _quantity,
                    payerEmail: user.email,
                    userId: user.uid,
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

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.dashboard);
  }
}

class _PaymentContent extends StatelessWidget {
  const _PaymentContent({
    required this.ride,
    required this.quantity,
    required this.paymentState,
    required this.currentUser,
    required this.onBack,
    required this.onStartCheckout,
  });

  final RidesEntity ride;
  final int quantity;
  final PaymentState paymentState;
  final AuthEntity? currentUser;
  final VoidCallback onBack;
  final VoidCallback onStartCheckout;

  @override
  Widget build(BuildContext context) {
    final isLoading = paymentState.status == PaymentFlowStatus.loading;
    final isApproved = paymentState.status == PaymentFlowStatus.approved;
    final isPending = paymentState.status == PaymentFlowStatus.pending;
    final isRejected = paymentState.status == PaymentFlowStatus.rejected;
    final payerEmail = currentUser?.email ?? 'No email available';
    final userId = currentUser?.uid;
    final fullName = currentUser?.fullName ?? 'No signed-in user';
    final amount = ride.pricePerSeat.toDouble();
    final canStartCheckout =
        !isLoading &&
        !isApproved &&
        !isPending &&
        userId != null &&
        payerEmail.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroCard(
            amount: amount,
            rideId: ride.id,
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
          const SizedBox(height: AppSpacing.l),
          _UserStatusCard(paymentState: paymentState, onBack: onBack),
          const SizedBox(height: AppSpacing.l),
          _DetailsCard(
            paymentState: paymentState,
            ride: ride,
            unitPrice: amount,
            quantity: quantity,
            payerEmail: payerEmail,
            userId: userId ?? 'No signed-in user',
            fullName: fullName,
          ),
          const SizedBox(height: AppSpacing.l),
          if (canStartCheckout)
            AppButton(
              label: 'Pay with Mercado Pago',
              onPressed: onStartCheckout,
            )
          else ...[
            AppButton(
              label: 'Back to dashboard',
              onPressed: onBack,
              isPrimary: false,
            ),
            if (isRejected) ...[
              const SizedBox(height: AppSpacing.s),
              AppButton(
                label: 'Try payment again',
                onPressed: userId == null ? null : onStartCheckout,
              ),
            ],
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.amount,
    required this.rideId,
    required this.title,
    required this.status,
  });

  final double amount;
  final String rideId;
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
            '\$${amount.toStringAsFixed(0)} COP',
            style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            '$title\nRide ID: $rideId',
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
        return 'We will keep checking Firestore until backend confirms the result.';
      case PaymentFlowStatus.rejected:
        return 'The payment could not be completed. You can go back or try again.';
      case PaymentFlowStatus.error:
        return 'We could not confirm the payment yet. Please return or try later.';
      case PaymentFlowStatus.idle:
      case PaymentFlowStatus.loading:
      case PaymentFlowStatus.checkoutOpened:
        return 'The checkout opens inside the app and waits for Firestore confirmation before marking payment as successful.';
    }
  }
}

class _UserStatusCard extends StatelessWidget {
  const _UserStatusCard({required this.paymentState, required this.onBack});

  final PaymentState paymentState;
  final VoidCallback onBack;

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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: _buttonLabel(status),
            onPressed: onBack,
            isPrimary: false,
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
        return 'Please wait while we check the final result in the database.';
      case PaymentFlowStatus.rejected:
        return 'You can return to your ride or try the payment again.';
      case PaymentFlowStatus.error:
        return 'Please return and try again later.';
      case PaymentFlowStatus.idle:
      case PaymentFlowStatus.loading:
      case PaymentFlowStatus.checkoutOpened:
        return '';
    }
  }

  String _buttonLabel(PaymentFlowStatus status) {
    switch (status) {
      case PaymentFlowStatus.approved:
        return 'Back to dashboard';
      case PaymentFlowStatus.pending:
        return 'Go back';
      case PaymentFlowStatus.rejected:
        return 'Back to dashboard';
      case PaymentFlowStatus.error:
        return 'Go back';
      case PaymentFlowStatus.idle:
      case PaymentFlowStatus.loading:
      case PaymentFlowStatus.checkoutOpened:
        return 'Go back';
    }
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.paymentState,
    required this.ride,
    required this.unitPrice,
    required this.quantity,
    required this.payerEmail,
    required this.userId,
    required this.fullName,
  });

  final PaymentState paymentState;
  final RidesEntity ride;
  final double unitPrice;
  final int quantity;
  final String payerEmail;
  final String userId;
  final String fullName;

  @override
  Widget build(BuildContext context) {
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
            'Payment details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: AppSpacing.m),
          _DetailRow(label: 'Passenger', value: fullName),
          _DetailRow(label: 'Payer', value: payerEmail),
          _DetailRow(label: 'User ID', value: userId),
          _DetailRow(label: 'Driver', value: ride.driverName),
          _DetailRow(label: 'Route', value: '${ride.origin} -> ${ride.destination}'),
          _DetailRow(label: 'Date', value: ride.dateLabel),
          _DetailRow(label: 'Departure', value: ride.departureLabel),
          _DetailRow(label: 'Quantity', value: quantity.toString()),
          _DetailRow(
            label: 'Unit price',
            value: '\$${unitPrice.toStringAsFixed(0)} COP',
          ),
          _DetailRow(label: 'Ride ID', value: paymentState.rideId ?? ride.id),
          _DetailRow(label: 'Flow status', value: paymentState.status.name),
          _DetailRow(
            label: 'DB status',
            value: paymentState.paymentRecord?.status ?? 'Waiting for update',
          ),
        ],
      ),
    );
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
