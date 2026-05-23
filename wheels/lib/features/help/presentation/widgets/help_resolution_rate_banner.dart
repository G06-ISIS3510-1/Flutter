import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_radius.dart';
import '../../../../theme/app_theme_palette.dart';
import '../providers/help_providers.dart';

/// BQ-J4 banner: shows the share of Help Center sessions in the last 7 days
/// that resolved without escalating to "contact support". Hidden when the
/// window does not have enough data to be meaningful (no sessions).
class HelpResolutionRateBanner extends ConsumerWidget {
  const HelpResolutionRateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateAsync = ref.watch(helpWeeklyResolutionRateProvider);
    return rateAsync.maybeWhen(
      data: (rate) {
        if (!rate.hasEnoughData) {
          return const SizedBox.shrink();
        }
        return _Banner(
          percent: rate.ratePercent,
          sessions: rate.sessionsStarted,
          escalations: rate.supportClicks,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.percent,
    required this.sessions,
    required this.escalations,
  });

  final int percent;
  final int sessions;
  final int escalations;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.secondarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.secondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              '$percent%',
              style: TextStyle(
                color: palette.primaryForeground,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This week, $percent% of help sessions resolved without '
                  'contacting support.',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last 7 days · $sessions ${sessions == 1 ? "session" : "sessions"} · '
                  '$escalations ${escalations == 1 ? "escalation" : "escalations"}',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 11,
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
