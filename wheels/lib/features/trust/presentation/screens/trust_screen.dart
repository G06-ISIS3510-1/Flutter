import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../providers/trust_providers.dart';

class TrustScreen extends ConsumerWidget {
  const TrustScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final trustAsync = ref.watch(trustViewDataProvider);
    final role = ref.watch(currentUserRoleProvider);

    return AppScaffold(
      title: 'Trust & Fairness',
      showAppBar: false,
      backgroundColor: palette.background,
      maxScrollableWidth: 440,
      scrollableHeader: _TrustHeader(
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.profile);
          }
        },
      ),
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.profile,
        role: role,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          0,
          AppSpacing.m,
          AppSpacing.l,
        ),
        child: trustAsync.when(
          data: (trust) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -26),
                child: _TrustOverviewCard(trust: trust),
              ),
              _SectionTitle(label: 'Performance Breakdown'),
              const SizedBox(height: AppSpacing.m),
              _PaymentReliabilityCard(data: trust.paymentReliability),
              const SizedBox(height: AppSpacing.m),
              _ConsistencyCard(data: trust.consistency),
              const SizedBox(height: AppSpacing.m),
              _CancellationCard(data: trust.cancellation),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(label: 'Accountability System'),
              const SizedBox(height: AppSpacing.m),
              _PolicyCard(steps: trust.policySteps, notice: trust.policyNotice),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(label: 'Trust Rewards'),
              const SizedBox(height: AppSpacing.m),
              _RewardsCard(
                rewardPoints: trust.rewardPoints,
                items: trust.rewardItems,
              ),
            ],
          ),
          loading: () => const _TrustLoadingBody(),
          error: (error, _) => _TrustErrorCard(message: '$error'),
        ),
      ),
    );
  }
}

class _TrustLoadingBody extends StatelessWidget {
  const _TrustLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _TrustErrorCard extends StatelessWidget {
  const _TrustErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Transform.translate(
      offset: const Offset(0, -26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(34),
          boxShadow: AppShadows.xl,
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: palette.warning,
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              'We could not calculate your trust score right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.primary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustHeader extends StatelessWidget {
  const _TrustHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
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
            'Trust & Fairness',
            style: TextStyle(
              color: palette.primaryForeground,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Your reliability and accountability metrics',
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

class _TrustOverviewCard extends StatelessWidget {
  const _TrustOverviewCard({required this.trust});

  final TrustViewData trust;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(34),
        boxShadow: AppShadows.xl,
      ),
      child: Column(
        children: [
          _ScoreRing(score: trust.score),
          const SizedBox(height: 24),
          Text(
            trust.headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            trust.headlineSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          _MetricsGrid(metrics: trust.metrics),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(190),
            painter: _ScoreRingPainter(
              progress: score / 100,
              trackColor: palette.border,
              startColor: palette.accent,
              endColor: palette.secondary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 58,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Score',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({
    required this.progress,
    required this.trackColor,
    required this.startColor,
    required this.endColor,
  });

  final double progress;
  final Color trackColor;
  final Color startColor;
  final Color endColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [startColor, endColor],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      (math.pi * 2 * progress).clamp(0.0, math.pi * 2).toDouble(),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.startColor != startColor ||
        oldDelegate.endColor != endColor;
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final List<TrustMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 320 ? 3 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _MetricTile(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final TrustMetricData metric;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: palette.cardSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: metric.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(metric.icon, color: metric.iconColor, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            metric.value,
            style: TextStyle(
              color: palette.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoCardShell extends StatelessWidget {
  const _InfoCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.lg,
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 30),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentReliabilityCard extends StatelessWidget {
  const _PaymentReliabilityCard({required this.data});

  final TrustPaymentReliabilityData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final progress = data.totalPayments == 0
        ? 0.0
        : data.completedPayments / data.totalPayments;

    return _InfoCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.attach_money_rounded,
            iconColor: Color(0xFF00D9A3),
            iconBackground: Color(0xFFEAFBF4),
            title: 'Payment Reliability',
            subtitle: 'Resolved payments improve your trust faster',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Resolved payments',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${data.completedPayments}/${data.totalPayments}',
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: palette.border,
              valueColor: AlwaysStoppedAnimation(palette.accent),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.successRateLabel,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.data});

  final TrustConsistencyData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return _InfoCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.schedule_rounded,
            iconColor: Color(0xFF5B89C8),
            iconBackground: Color(0xFFEAF2FD),
            title: 'Consistency Signals',
            subtitle: 'Ride completion and account maturity',
          ),
          const SizedBox(height: 20),
          _MetricLine(
            label: data.primaryLabel,
            value: data.primaryValue,
          ),
          const SizedBox(height: 14),
          _MetricLine(
            label: data.secondaryLabel,
            value: data.secondaryValue,
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: palette.accent,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    data.message,
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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

class _CancellationCard extends StatelessWidget {
  const _CancellationCard({required this.data});

  final TrustCancellationData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return _InfoCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.warning_amber_rounded,
            iconColor: Color(0xFFFFA726),
            iconBackground: Color(0xFFFFF3E8),
            title: 'Cancellation Record',
            subtitle: 'Last-minute cancellations impact score',
          ),
          const SizedBox(height: 20),
          _MetricLine(
            label: 'Total cancellations',
            value: '${data.totalCancellations}',
          ),
          const SizedBox(height: 14),
          _MetricLine(label: 'Cancellation rate', value: data.cancellationRate),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.warning.withValues(alpha: 0.35)),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 15,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Note: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: data.note,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
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
        Text(
          value,
          style: TextStyle(
            color: palette.primary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.steps, required this.notice});

  final List<TrustPolicyStepData> steps;
  final String notice;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return _InfoCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: palette.primary, size: 34),
              const SizedBox(width: 14),
              Text(
                'Cancellation Policy',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          for (final step in steps) ...[
            _PolicyStep(step: step),
            if (step != steps.last) const SizedBox(height: 16),
          ],
          const SizedBox(height: 20),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: 18),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 15,
                height: 1.55,
              ),
              children: [
                TextSpan(
                  text: 'Important: ',
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: notice,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyStep extends StatelessWidget {
  const _PolicyStep({required this.step});

  final TrustPolicyStepData step;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: step.stepColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${step.stepNumber}',
            style: TextStyle(
              color: palette.primaryForeground,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                step.description,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({required this.rewardPoints, required this.items});

  final int rewardPoints;
  final List<TrustRewardItemData> items;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.accent, palette.accent.withBlue(140)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward Points',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Earn points for good behavior',
                      style: TextStyle(
                        color: Color(0xFFE9FFF6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$rewardPoints',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'points',
                    style: TextStyle(
                      color: Color(0xFFE9FFF6),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                for (final item in items) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        item.pointsLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (item != items.last) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Redeem points for ride discounts and exclusive perks',
            style: TextStyle(
              color: Color(0xFFE9FFF6),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
