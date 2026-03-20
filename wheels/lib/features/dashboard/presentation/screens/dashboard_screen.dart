import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_theme_drawer.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../../rides/presentation/mock/driver_active_ride_mock.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final summary = ref.watch(dashboardSummaryProvider);
    final role = ref.watch(currentUserRoleProvider);
    final canOpenActiveRide = role == UserRole.driver;

    return AppScaffold(
      title: 'Dashboard',
      showAppBar: false,
      backgroundColor: palette.background,
      maxScrollableWidth: 440,
      scrollableHeader: const _DashboardHeader(),
      drawer: const AppNavigationDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.home,
        role: role,
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _MapCard(),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _CurrentRideCard(
              onTap: canOpenActiveRide
                  ? () => context.go(AppRoutes.activeRide)
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _UpdatesSection(),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              summary,
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (context) {
                  return _CircleIconButton(
                    icon: Icons.menu,
                    onTap: () => Scaffold.of(context).openDrawer(),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        color: palette.primaryForeground.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Maria',
                      style: TextStyle(
                        color: palette.primaryForeground,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              _BellButton(onTap: () => context.go(AppRoutes.notifications)),
            ],
          ),
          const SizedBox(height: 14),
          const _StatsRow(),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        const Expanded(child: _StatCard(value: '12', label: 'Rides')),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '98%',
            label: 'Score',
            valueColor: palette.accent,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: _StatCard(value: '4.9', label: 'Rating')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: palette.primaryForeground.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? palette.primaryForeground,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: palette.primaryForeground.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.lg,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(painter: _GridPainter(palette: palette)),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(999),
                boxShadow: AppShadows.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: palette.accent),
                  const SizedBox(width: 8),
                  Text(
                    '3 min away',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.accent, width: 4),
                  boxShadow: AppShadows.lg,
                ),
                child: Icon(Icons.near_me, color: palette.primary),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(999),
                boxShadow: AppShadows.sm,
              ),
              child: Icon(Icons.near_me, color: palette.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentRideCard extends StatelessWidget {
  const _CurrentRideCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ride = DriverActiveRideMock.ride;

    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current Ride',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: palette.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${ride['driverInitials']}',
                  style: TextStyle(
                    color: palette.primaryForeground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ride['driverName']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          '${ride['driverRating']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${ride['carModel']}',
                            style: TextStyle(color: palette.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SmallActionButton(
                icon: Icons.chat_bubble_outline,
                onTap: () => context.go(
                  AppRoutes.groupChatByTripId('dashboard-active-trip'),
                ),
              ),
              const SizedBox(width: 8),
              _SmallActionButton(icon: Icons.call_outlined, onTap: () {}),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: palette.border),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.circle,
            iconColor: const Color(0xFF3B82F6),
            label: 'Pickup',
            value: '${ride['origin']}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.location_on_outlined,
            iconColor: palette.textSecondary,
            label: 'Destination',
            value: '${ride['destination']}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Trip Progress',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '45%',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.45,
              minHeight: 8,
              backgroundColor: palette.border,
              valueColor: AlwaysStoppedAnimation(palette.accent),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  title: 'Distance',
                  value: '${ride['distance']}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniMetric(title: 'Fare', value: '${ride['fare']}'),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return GestureDetector(onTap: onTap, child: content);
  }
}

class _UpdatesSection extends StatelessWidget {
  const _UpdatesSection();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Updates',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _UpdateCard(
          icon: Icons.near_me,
          iconBg: palette.accent,
          title: 'Driver arriving soon',
          subtitle: 'Carlos is 3 minutes away from pickup',
          highlight: true,
          actionLabel: 'Quick Pay',
          onAction: () => context.go(AppRoutes.payment),
        ),
        const SizedBox(height: 10),
        _UpdateCard(
          icon: Icons.star_border,
          iconBg: palette.border,
          iconColor: palette.secondary,
          title: 'You earned punctuality points!',
          subtitle: '+5 points for being on time',
          trailing: '5m',
        ),
      ],
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.icon,
    required this.iconBg,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.highlight = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconBg;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? trailing;
  final bool highlight;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? palette.accentSoft : palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? palette.accent.withValues(alpha: 0.35) : palette.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: iconColor ?? palette.primaryForeground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: palette.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (actionLabel != null && onAction != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [palette.accent, palette.accent.withBlue(140)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.credit_card_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          actionLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                color: palette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: palette.input,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: palette.primary),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: palette.primaryForeground.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: palette.primaryForeground),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.primaryForeground.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              Icons.notifications_none,
              color: palette.primaryForeground,
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.palette});

  final AppThemePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = palette.input;
    canvas.drawRect(Offset.zero & size, bg);

    final gridPaint = Paint()
      ..color = palette.border
      ..strokeWidth = 1;

    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pathPaint = Paint()
      ..color = palette.textSecondary.withValues(alpha: 0.75)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.45,
        size.width * 0.82,
        size.height * 0.35,
      );

    const dash = 10.0;
    const gap = 8.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          pathPaint,
        );
        distance += dash + gap;
      }
    }

    final pickupDot = Paint()..color = palette.secondary;
    canvas.drawCircle(Offset(size.width * 0.27, size.height * 0.78), 5, pickupDot);

    final rideDot = Paint()..color = palette.accent;
    canvas.drawCircle(Offset(size.width * 0.58, size.height * 0.48), 8, rideDot);

    final destinationDot = Paint()..color = palette.textPrimary;
    canvas.drawCircle(
      Offset(size.width * 0.83, size.height * 0.36),
      6,
      destinationDot,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}
