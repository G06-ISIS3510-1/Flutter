import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(authStepProvider);

    return AppScaffold(
      title: 'Register',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Register Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text('Current register step: $step'),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Back to Login',
            onPressed: () => context.go(AppRoutes.login),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Forgot Password',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.forgotPassword),
          ),
        ],
      ),
    );
  }
}
