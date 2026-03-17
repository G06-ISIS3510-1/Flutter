import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';

enum QuickPaymentMethod { card, wallet, qr }

class QuickPaymentViewData {
  const QuickPaymentViewData({
    required this.amountLabel,
    required this.protectionLabel,
    required this.driverName,
    required this.driverRole,
    required this.driverInitials,
    required this.origin,
    required this.destination,
    required this.scheduleLabel,
    required this.methods,
    required this.securePaymentTitle,
    required this.securePaymentMessage,
    required this.bonusLabel,
  });

  final String amountLabel;
  final String protectionLabel;
  final String driverName;
  final String driverRole;
  final String driverInitials;
  final String origin;
  final String destination;
  final String scheduleLabel;
  final List<QuickPaymentMethodData> methods;
  final String securePaymentTitle;
  final String securePaymentMessage;
  final String bonusLabel;
}

class QuickPaymentMethodData {
  const QuickPaymentMethodData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.subtitleColor = AppColors.textSecondary,
  });

  final QuickPaymentMethod id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color subtitleColor;
}

const _quickPaymentData = QuickPaymentViewData(
  amountLabel: '\$3,500',
  protectionLabel: 'Payment protected',
  driverName: 'Carlos Mendez',
  driverRole: 'Driver',
  driverInitials: 'CM',
  origin: 'Campus Uniandes',
  destination: 'Centro Comercial Andino',
  scheduleLabel: 'Today, 14:30',
  methods: [
    QuickPaymentMethodData(
      id: QuickPaymentMethod.card,
      title: 'Credit/Debit Card',
      subtitle: '•••• 4532',
      icon: Icons.credit_card_rounded,
    ),
    QuickPaymentMethodData(
      id: QuickPaymentMethod.wallet,
      title: 'Digital Wallet',
      subtitle: 'Balance: \$15,000',
      icon: Icons.account_balance_wallet_outlined,
      subtitleColor: AppColors.accent,
    ),
    QuickPaymentMethodData(
      id: QuickPaymentMethod.qr,
      title: 'QR Code Payment',
      subtitle: 'Scan QR to pay',
      icon: Icons.qr_code_2_rounded,
    ),
  ],
  securePaymentTitle: 'Secure Payment',
  securePaymentMessage:
      'Your payment information is encrypted and secure. Funds are held until ride completion.',
  bonusLabel: 'On-time payment bonus: Earn +3 points',
);

final quickPaymentDataProvider = Provider<QuickPaymentViewData>(
  (ref) => _quickPaymentData,
);

final selectedQuickPaymentMethodProvider = StateProvider<QuickPaymentMethod>(
  (ref) => QuickPaymentMethod.card,
);

final paymentsStatusProvider = Provider<String>((ref) {
  final selectedMethod = ref.watch(selectedQuickPaymentMethodProvider);

  return switch (selectedMethod) {
    QuickPaymentMethod.card => 'Card selected for quick payment',
    QuickPaymentMethod.wallet => 'Wallet selected for quick payment',
    QuickPaymentMethod.qr => 'QR payment selected for quick payment',
  };
});

final savedPaymentMethodsProvider = Provider<int>(
  (ref) => ref.watch(quickPaymentDataProvider).methods.length,
);
