import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/payments_providers.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentStatus = ref.watch(paymentsStatusProvider);

    return AppScaffold(
      title: 'Payment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text(paymentStatus),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Back to Create Ride',
            onPressed: () => context.go(AppRoutes.createRide),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Open Profile',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
    );
  }
}
