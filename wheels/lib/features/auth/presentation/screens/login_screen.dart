import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authStatusProvider);

    return AppScaffold(
      title: 'Login',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Login Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text('Auth state: $status'),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Go to Register',
            onPressed: () => context.go(AppRoutes.register),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Open Dashboard',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ],
      ),
    );
  }
}
