import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/payment_flow_status.dart';
import '../providers/payment_provider.dart';
import '../widgets/payment_status_banner.dart';
import 'checkout_webview_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  static const _rideId = 'ride_123';
  static const _title = 'Ride payment - Wheels';
  static const _unitPrice = 1000.0;
  static const _quantity = 1;

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
              rideId: next.rideId ?? _rideId,
            ),
          ),
        );
      });
    });

    final paymentState = ref.watch(paymentProvider);
    final currentUser = ref.watch(authUserProvider);
    final isLoading = paymentState.status == PaymentFlowStatus.loading;
    final isApproved = paymentState.status == PaymentFlowStatus.approved;
    final isPending = paymentState.status == PaymentFlowStatus.pending;
    final isRejected = paymentState.status == PaymentFlowStatus.rejected;
    final payerEmail = currentUser?.email ?? 'No email available';
    final userId = currentUser?.uid;
    final fullName = currentUser?.fullName ?? 'No signed-in user';
    final canStartCheckout =
        !isLoading &&
        !isApproved &&
        !isPending &&
        userId != null &&
        payerEmail.trim().isNotEmpty;

    return AppScaffold(
      title: 'Ride payment',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroCard(
              amount: _unitPrice,
              rideId: _rideId,
              title: _title,
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
            _UserStatusCard(
              paymentState: paymentState,
              onBack: () => _goBack(context),
            ),
            const SizedBox(height: AppSpacing.l),
            _DetailsCard(
              paymentState: paymentState,
              unitPrice: _unitPrice,
              quantity: _quantity,
              payerEmail: payerEmail,
              userId: userId ?? 'No signed-in user',
              fullName: fullName,
              fallbackRideId: _rideId,
            ),
            const SizedBox(height: AppSpacing.l),
            if (canStartCheckout)
              AppButton(
                label: 'Pay with Mercado Pago',
                onPressed: () {
                  ref.read(paymentProvider.notifier).startCheckout(
                    rideId: _rideId,
                    title: _title,
                    unitPrice: _unitPrice,
                    quantity: _quantity,
                    payerEmail: payerEmail,
                    userId: userId,
                  );
                },
              ),
            if (!canStartCheckout) ...[
              AppButton(
                label: 'Back to dashboard',
                onPressed: () => _goBack(context),
                isPrimary: false,
              ),
              if (isRejected) ...[
                const SizedBox(height: AppSpacing.s),
                AppButton(
                  label: 'Try payment again',
                  onPressed: userId == null
                      ? null
                      : () {
                          ref.read(paymentProvider.notifier).startCheckout(
                            rideId: _rideId,
                            title: _title,
                            unitPrice: _unitPrice,
                            quantity: _quantity,
                            payerEmail: payerEmail,
                            userId: userId,
                          );
                        },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.dashboard);
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
    required this.unitPrice,
    required this.quantity,
    required this.payerEmail,
    required this.userId,
    required this.fullName,
    required this.fallbackRideId,
  });

  final PaymentState paymentState;
  final double unitPrice;
  final int quantity;
  final String payerEmail;
  final String userId;
  final String fullName;
  final String fallbackRideId;

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
          _DetailRow(label: 'User ID', value: userId),
          _DetailRow(label: 'Payer', value: payerEmail),
          _DetailRow(label: 'Quantity', value: quantity.toString()),
          _DetailRow(
            label: 'Unit price',
            value: '\$${unitPrice.toStringAsFixed(0)} COP',
          ),
          _DetailRow(
            label: 'Ride ID',
            value: paymentState.rideId ?? fallbackRideId,
          ),
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
