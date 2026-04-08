import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/utils/app_formatter.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/wallet_summary.dart';
import '../providers/wallet_providers.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(authUserProvider);
    final walletSummaryAsync = ref.watch(driverWalletSummaryProvider);
    final palette = context.palette;

    return AppScaffold(
      title: 'Driver Wallet',
      actions: [
        IconButton(
          onPressed: () => ref.invalidate(driverWalletSummaryProvider),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh wallet',
        ),
      ],
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.profile,
        role: role,
      ),
      child: user == null || role != UserRole.driver
          ? const _WalletAccessCard()
          : walletSummaryAsync.when(
              loading: () => const _WalletLoadingState(),
              error: (error, _) => _WalletErrorState(
                message: error.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(driverWalletSummaryProvider),
              ),
              data: (summary) {
                if (summary == null) {
                  return const _WalletAccessCard();
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WalletHeroCard(summary: summary),
                      const SizedBox(height: AppSpacing.l),
                      if (summary.isEmpty) ...[
                        const _WalletEmptyState(),
                        const SizedBox(height: AppSpacing.l),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _WalletStatCard(
                              label: 'Available',
                              value: AppFormatter.cop(summary.availableBalance),
                              icon: Icons.account_balance_wallet_outlined,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: _WalletStatCard(
                              label: 'Pending withdrawal',
                              value: AppFormatter.cop(
                                summary.pendingWithdrawalBalance,
                              ),
                              icon: Icons.hourglass_top_rounded,
                              color: palette.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      _WalletStatCard(
                        label: 'Total earned',
                        value: AppFormatter.cop(summary.totalEarned),
                        icon: Icons.trending_up_rounded,
                        color: palette.accent,
                        fullWidth: true,
                      ),
                      const SizedBox(height: AppSpacing.l),
                      const _WalletInfoCard(),
                      const SizedBox(height: AppSpacing.l),
                      AppButton(
                        label: summary.canRequestWithdrawal
                            ? 'Request withdrawal'
                            : 'Withdrawal available from COP 10.000',
                        onPressed: summary.canRequestWithdrawal
                            ? () => context.go(AppRoutes.withdrawalRequest)
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _WalletHeroCard extends StatelessWidget {
  const _WalletHeroCard({required this.summary});

  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.primary, palette.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver wallet',
            style: TextStyle(
              color: palette.primaryForeground,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            AppFormatter.cop(summary.availableBalance),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: palette.primaryForeground,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            summary.canRequestWithdrawal
                ? 'Your available balance already meets the minimum withdrawal amount.'
                : 'Minimum withdrawal amount: COP 10.000.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.primaryForeground.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletStatCard extends StatelessWidget {
  const _WalletStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletInfoCard extends StatelessWidget {
  const _WalletInfoCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.secondarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Withdrawal rules',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Minimum withdrawal: COP 10.000. Only one pending request is allowed at a time, and requests are processed manually later.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _WalletAccessCard extends StatelessWidget {
  const _WalletAccessCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 42,
              color: palette.primary,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Wallet available for drivers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Sign in with a driver account to view accumulated earnings and request withdrawals.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletLoadingState extends StatelessWidget {
  const _WalletLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _WalletErrorState extends StatelessWidget {
  const _WalletErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: palette.error),
            const SizedBox(height: AppSpacing.m),
            Text(
              'We could not load the wallet summary.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.m),
            AppButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _WalletEmptyState extends StatelessWidget {
  const _WalletEmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No accumulated earnings yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Your driver wallet will show real earnings here after approved in-app Mercado Pago payments credit your balance.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
