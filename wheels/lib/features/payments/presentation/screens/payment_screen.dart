import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../providers/payments_providers.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final payment = ref.watch(quickPaymentDataProvider);
    final selectedMethod = ref.watch(selectedQuickPaymentMethodProvider);

    return Scaffold(
      backgroundColor: palette.background,
      bottomNavigationBar: _PaymentFooter(
        amountLabel: payment.amountLabel,
        bonusLabel: payment.bonusLabel,
        onPay: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  '${payment.amountLabel} paid successfully with ${_methodLabel(selectedMethod)}.',
                ),
              ),
            );
          context.go(AppRoutes.dashboard);
        },
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _QuickPayHeader(
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.dashboard);
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                    ),
                    child: Transform.translate(
                      offset: const Offset(0, -30),
                      child: _AmountCard(payment: payment),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.m,
                      0,
                      AppSpacing.m,
                      AppSpacing.l,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(label: 'Ride Summary'),
                        const SizedBox(height: AppSpacing.m),
                        _RideSummaryCard(payment: payment),
                        const SizedBox(height: AppSpacing.xl),
                        _SectionTitle(label: 'Payment Method'),
                        const SizedBox(height: AppSpacing.m),
                        for (final method in payment.methods) ...[
                          _PaymentMethodTile(
                            method: method,
                            isSelected: method.id == selectedMethod,
                            onTap: () {
                              ref
                                  .read(
                                    selectedQuickPaymentMethodProvider.notifier,
                                  )
                                  .state = method.id;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        const SizedBox(height: 6),
                        _SecurePaymentCard(payment: payment),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _methodLabel(QuickPaymentMethod method) {
    return switch (method) {
      QuickPaymentMethod.card => 'card',
      QuickPaymentMethod.wallet => 'digital wallet',
      QuickPaymentMethod.qr => 'QR code',
    };
  }
}

class _QuickPayHeader extends StatelessWidget {
  const _QuickPayHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primary, palette.primaryLight],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            style: TextButton.styleFrom(
              foregroundColor: palette.primaryForeground,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            ),
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            label: const Text(
              'Back',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'Quick Payment',
            style: TextStyle(
              color: palette.primaryForeground,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Fast and secure ride payment',
            style: TextStyle(
              color: palette.primaryForeground.withValues(alpha: 0.82),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.payment});

  final QuickPaymentViewData payment;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(34),
        boxShadow: AppShadows.xl,
      ),
      child: Column(
        children: [
          Text(
            'Amount to pay',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            payment.amountLabel,
            style: TextStyle(
              color: palette.primary,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: palette.accent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  payment.protectionLabel,
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Text(
      label,
      style: TextStyle(
        color: palette.textSecondary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _RideSummaryCard extends StatelessWidget {
  const _RideSummaryCard({required this.payment});

  final QuickPaymentViewData payment;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.secondary, palette.primary],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  payment.driverInitials,
                  style: TextStyle(
                    color: palette.primaryForeground,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.driverName,
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.driverRole,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: 18),
          _SummaryRow(label: 'From', value: payment.origin),
          const SizedBox(height: 14),
          _SummaryRow(label: 'To', value: payment.destination),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Date & Time', value: payment.scheduleLabel),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: palette.primary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final QuickPaymentMethodData method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? palette.secondarySoft : palette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? palette.secondary : palette.border,
              width: isSelected ? 1.6 : 1.2,
            ),
            boxShadow: isSelected ? null : AppShadows.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected ? palette.secondary : palette.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  method.icon,
                  color: isSelected
                      ? palette.primaryForeground
                      : palette.textSecondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.title,
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.subtitle,
                      style: TextStyle(
                        color: method.id == QuickPaymentMethod.wallet
                            ? palette.accent
                            : palette.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? palette.secondary : palette.card,
                  border: Border.all(
                    color: isSelected ? palette.secondary : palette.border,
                    width: 1.6,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: palette.primaryForeground,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurePaymentCard extends StatelessWidget {
  const _SecurePaymentCard({required this.payment});

  final QuickPaymentViewData payment;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.secondarySoft,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.card,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              color: palette.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.securePaymentTitle,
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  payment.securePaymentMessage,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentFooter extends StatelessWidget {
  const _PaymentFooter({
    required this.amountLabel,
    required this.bonusLabel,
    required this.onPay,
  });

  final String amountLabel;
  final String bonusLabel;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            12,
            AppSpacing.m,
            AppSpacing.m,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: palette.accent,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      bonusLabel,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.accent, palette.accent.withBlue(140)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.lg,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPay,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pay $amountLabel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
