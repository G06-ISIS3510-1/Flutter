import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/utils/app_formatter.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/local_wallet_summary_cache_model.dart';
import '../../domain/entities/wallet_summary.dart';
import '../providers/wallet_providers.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  LocalWalletSummaryCacheModel? _cachedWalletSnapshot;
  bool _isRestoringCache = true;
  bool _isUsingCachedFallback = false;
  Object? _lastLiveError;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_restoreWalletSnapshot);
  }

  Future<void> _restoreWalletSnapshot() async {
    final cache = await ref
        .read(walletSummaryLocalDataSourceProvider)
        .loadLatestWalletSummary();
    if (!mounted) {
      return;
    }

    setState(() {
      _cachedWalletSnapshot = cache;
      _isRestoringCache = false;
    });
  }

  Future<void> _persistWalletSnapshot(WalletSummary summary) async {
    final snapshot = LocalWalletSummaryCacheModel.create(summary: summary);
    await ref
        .read(walletSummaryLocalDataSourceProvider)
        .saveLatestWalletSummary(snapshot);

    if (!mounted) {
      return;
    }

    setState(() {
      _cachedWalletSnapshot = snapshot;
      _isUsingCachedFallback = false;
      _lastLiveError = null;
    });
  }

  void _handleWalletSummaryUpdate(
    AsyncValue<WalletSummary?>? previous,
    AsyncValue<WalletSummary?> next,
  ) {
    next.whenData((summary) {
      if (summary == null) {
        return;
      }

      _persistWalletSnapshot(summary);
    });

    if (!mounted) {
      return;
    }

    if (next.hasError) {
      final shouldUseCache = _cachedWalletSnapshot != null;
      setState(() {
        _lastLiveError = next.error;
        _isUsingCachedFallback = shouldUseCache;
      });
      return;
    }

    if (previous?.hasError == true && next.isLoading) {
      return;
    }

    if (_isUsingCachedFallback || _lastLiveError != null) {
      setState(() {
        _isUsingCachedFallback = false;
        _lastLiveError = null;
      });
    }
  }

  void _handleConnectivityUpdate(
    AsyncValue<bool>? previous,
    AsyncValue<bool> next,
  ) {
    final wasOnline = previous?.valueOrNull ?? true;
    final isOnline = next.valueOrNull ?? true;

    if (!mounted || !isOnline || wasOnline == isOnline) {
      return;
    }

    if (_isUsingCachedFallback || _lastLiveError != null) {
      ref.invalidate(driverWalletSummaryProvider);
    }
  }

  void _refreshWalletSummary() {
    ref.invalidate(driverWalletSummaryProvider);
  }

  String _formatCachedAt(DateTime savedAt) {
    final date = '${savedAt.day}/${savedAt.month}/${savedAt.year}';
    final hour = TimeOfDay.fromDateTime(savedAt).format(context);
    return '$date at $hour';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<WalletSummary?>>(
      driverWalletSummaryProvider,
      _handleWalletSummaryUpdate,
    );
    ref.listen<AsyncValue<bool>>(
      connectivityStatusProvider,
      _handleConnectivityUpdate,
    );

    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(authUserProvider);
    final walletSummaryAsync = ref.watch(driverWalletSummaryProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final isOnline = connectivityAsync.valueOrNull ?? true;

    final liveSummary = walletSummaryAsync.valueOrNull;
    final cachedSummary = _cachedWalletSnapshot?.toEntity();
    final shouldUseCachedSummary =
        cachedSummary != null &&
        (!isOnline ||
            _isUsingCachedFallback ||
            (walletSummaryAsync.hasError && liveSummary == null));
    final summary = shouldUseCachedSummary ? cachedSummary : liveSummary;
    final cachedAt = _cachedWalletSnapshot?.savedAt;

    final Widget child;
    if (user == null || role != UserRole.driver) {
      child = const _WalletAccessCard();
    } else if (summary != null) {
      child = _WalletContent(
        summary: summary,
        showCachedNotice: shouldUseCachedSummary,
        isOnline: isOnline,
        cachedAtLabel: cachedAt == null ? null : _formatCachedAt(cachedAt),
      );
    } else if (walletSummaryAsync.isLoading || _isRestoringCache) {
      child = const _WalletLoadingState();
    } else if (walletSummaryAsync.hasError) {
      child = _WalletErrorState(
        message: walletSummaryAsync.error.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        onRetry: _refreshWalletSummary,
      );
    } else {
      child = const _WalletAccessCard();
    }

    return AppScaffold(
      title: 'Driver Wallet',
      actions: [
        IconButton(
          onPressed: _refreshWalletSummary,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh wallet',
        ),
      ],
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.profile,
        role: role,
      ),
      child: child,
    );
  }
}

class _WalletContent extends StatelessWidget {
  const _WalletContent({
    required this.summary,
    required this.showCachedNotice,
    required this.isOnline,
    required this.cachedAtLabel,
  });

  final WalletSummary summary;
  final bool showCachedNotice;
  final bool isOnline;
  final String? cachedAtLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCachedNotice) ...[
            _WalletCachedNotice(
              isOnline: isOnline,
              cachedAtLabel: cachedAtLabel,
            ),
            const SizedBox(height: AppSpacing.l),
          ],
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
                  value: AppFormatter.cop(summary.pendingWithdrawalBalance),
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
  }
}

class _WalletCachedNotice extends StatelessWidget {
  const _WalletCachedNotice({
    required this.isOnline,
    required this.cachedAtLabel,
  });

  final bool isOnline;
  final String? cachedAtLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final title = isOnline ? 'Showing cached wallet data' : 'You are offline';
    final message = isOnline
        ? cachedAtLabel == null
              ? 'A live refresh failed, so the latest wallet snapshot remains visible.'
              : 'A live refresh failed, so the wallet snapshot saved on $cachedAtLabel remains visible.'
        : cachedAtLabel == null
        ? 'Your latest saved wallet summary is being shown until connectivity returns.'
        : 'Your wallet snapshot saved on $cachedAtLabel is being shown until connectivity returns.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_rounded, color: palette.warning),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
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
