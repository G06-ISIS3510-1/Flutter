import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/payment_flow_status.dart';

class PaymentStatusBanner extends StatelessWidget {
  const PaymentStatusBanner({required this.status, this.message, super.key});

  final PaymentFlowStatus status;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible(status)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final config = _BannerConfig.fromStatus(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config.icon, color: config.iconColor),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message ?? config.defaultMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
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

  bool _isVisible(PaymentFlowStatus status) {
    return status == PaymentFlowStatus.approved ||
        status == PaymentFlowStatus.pending ||
        status == PaymentFlowStatus.rejected ||
        status == PaymentFlowStatus.error;
  }
}

class _BannerConfig {
  const _BannerConfig({
    required this.title,
    required this.defaultMessage,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  final String title;
  final String defaultMessage;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;

  factory _BannerConfig.fromStatus(PaymentFlowStatus status) {
    switch (status) {
      case PaymentFlowStatus.approved:
        return const _BannerConfig(
          title: 'Payment approved',
          defaultMessage: 'Your ride payment was confirmed by the backend.',
          icon: Icons.check_circle_rounded,
          backgroundColor: Color(0xFFE9FBF4),
          borderColor: Color(0xFFB8EBD6),
          iconColor: AppColors.success,
        );
      case PaymentFlowStatus.pending:
        return const _BannerConfig(
          title: 'Payment pending',
          defaultMessage: 'Mercado Pago is processing your payment.',
          icon: Icons.schedule_rounded,
          backgroundColor: Color(0xFFFFF4E5),
          borderColor: Color(0xFFFFD9A6),
          iconColor: AppColors.warning,
        );
      case PaymentFlowStatus.rejected:
        return const _BannerConfig(
          title: 'Payment rejected',
          defaultMessage: 'The payment was rejected or cancelled.',
          icon: Icons.cancel_rounded,
          backgroundColor: Color(0xFFFFEBEE),
          borderColor: Color(0xFFFFCDD2),
          iconColor: AppColors.error,
        );
      case PaymentFlowStatus.error:
        return const _BannerConfig(
          title: 'Payment error',
          defaultMessage: 'We could not confirm the payment status.',
          icon: Icons.error_rounded,
          backgroundColor: Color(0xFFE8F1FD),
          borderColor: Color(0xFFC6DCF7),
          iconColor: AppColors.info,
        );
      case PaymentFlowStatus.idle:
      case PaymentFlowStatus.loading:
      case PaymentFlowStatus.checkoutOpened:
        return const _BannerConfig(
          title: '',
          defaultMessage: '',
          icon: Icons.info_outline,
          backgroundColor: Colors.transparent,
          borderColor: Colors.transparent,
          iconColor: Colors.transparent,
        );
    }
  }
}
