import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authStatusProvider);

    return AppScaffold(
      title: 'Forgot Password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Forgot Password Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text('Status: $status'),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Back to Login',
            onPressed: () => context.go(AppRoutes.login),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Go to Register',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.register),
          ),
        ],
      ),
    );
  }
}
