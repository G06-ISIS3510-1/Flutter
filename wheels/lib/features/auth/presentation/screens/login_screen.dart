import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme_palette.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _LoginScaffold(child: _LoginBody());
  }
}

/// Usamos tu AppScaffold, pero sin AppBar para que se vea como el mockup.
class _LoginScaffold extends StatelessWidget {
  final Widget child;
  const _LoginScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: child,
        ),
      ),
    );
  }
}

class _LoginBody extends ConsumerWidget {
  const _LoginBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authStatusProvider);
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),

        // Logo
        Center(
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: palette.primary,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  color: Colors.black.withValues(alpha: 0.10),
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.add, color: Color(0xFF22C55E), size: 34),
            ),
          ),
        ),

        const SizedBox(height: 18),
        Center(
          child: Text(
            'Wheels',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Smart student ride coordination',
            style: TextStyle(fontSize: 16, color: palette.textSecondary),
          ),
        ),

        const SizedBox(height: 22),

        // Info card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Safe rides. Verified students only.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Join a trusted community of university students sharing safe, reliable rides.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Two small cards
        const Row(
          children: [
            Expanded(
              child: _MiniFeature(
                icon: Icons.groups_2_outlined,
                iconColor: Color(0xFF22C55E),
                title: 'Student-only\ncommunity',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MiniFeature(
                icon: Icons.schedule,
                iconColor: Color(0xFF3B82F6),
                title: 'Coordinated\nschedules',
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Primary button: usando tu AppButton (quedará con colorScheme.primary)
        AppButton(
          label: 'Continue with University Email',
          onPressed: () => context.push('${AppRoutes.register}?mode=login'),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: palette.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: palette.border),
            ),
            onPressed: () => context.go(AppRoutes.register),
            child: const Text(
              'Create account',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Text(
          "By continuing, you agree to Wheels' Terms of Service and Privacy\nPolicy",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: palette.textSecondary,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 10),

        // links
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.go(AppRoutes.forgotPassword),
              child: const Text('Forgot password?'),
            ),
          ],
        ),

        // Debug info (opcional: puedes borrarlo si no lo quieres en UI)
        const SizedBox(height: 8),
        Text(
          'Auth state: $status',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: palette.textSecondary),
        ),
      ],
    );
  }
}

class _MiniFeature extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _MiniFeature({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
