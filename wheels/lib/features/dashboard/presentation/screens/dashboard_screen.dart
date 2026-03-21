import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_theme_drawer.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../../rides/presentation/models/ride_listing.dart';
import '../../../rides/presentation/providers/rides_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final summary = ref.watch(dashboardSummaryProvider);
    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(authUserProvider);
    final fullName = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'Wheels User';
    final firstName = fullName.split(RegExp(r'\s+')).first;

    return AppScaffold(
      title: 'Dashboard',
      showAppBar: false,
      backgroundColor: palette.background,
      maxScrollableWidth: 440,
      scrollableHeader: _DashboardHeader(
        firstName: firstName,
        email: user?.email ?? 'No email available',
      ),
      drawer: const AppNavigationDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.home,
        role: role,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.s),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: _MapCard(),
          ),
          const SizedBox(height: AppSpacing.m),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: _CurrentRideCard(),
          ),
          const SizedBox(height: AppSpacing.m),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: _UpdatesSection(),
          ),
          const SizedBox(height: AppSpacing.s),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Text(
              summary,
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.firstName, required this.email});

  final String firstName;
  final String email;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.l,
      ),
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
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        color: palette.primaryForeground.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: TextStyle(
                        color: palette.primaryForeground,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.primaryForeground.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _CircleIconButton(
                icon: Icons.notifications_none,
                onTap: () => context.go(AppRoutes.notifications),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
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
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: _StatCard(
            value: '98%',
            label: 'Score',
            valueColor: palette.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
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
                    'Campus rides',
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
        ],
      ),
    );
  }
}

class _CurrentRideCard extends ConsumerWidget {
  const _CurrentRideCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final rideAsync = ref.watch(currentDriverRideProvider);
    final role = ref.watch(currentUserRoleProvider);

    if (role != UserRole.driver) {
      return _InfoCard(
        title: 'Passenger Home',
        subtitle: 'Search available rides and apply with your account.',
        actionLabel: 'Search Rides',
        onAction: () => context.go(AppRoutes.rides),
      );
    }

    return rideAsync.when(
      loading: () => const _LoadingCard(title: 'Current Ride'),
      error: (error, _) => _InfoCard(
        title: 'Current Ride',
        subtitle: error.toString(),
      ),
      data: (ride) {
        if (ride == null) {
          return _InfoCard(
            title: 'Current Ride',
            subtitle: 'You do not have an active ride yet.',
            actionLabel: 'Create Ride',
            onAction: () => context.go(AppRoutes.createRide),
          );
        }

        return GestureDetector(
          onTap: () => context.go(AppRoutes.activeRideById(ride.id)),
          child: Container(
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
                        ride.isInProgress ? 'In Progress' : 'Open',
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
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: palette.primaryLight,
                      child: Text(
                        ride.driverInitials,
                        style: TextStyle(
                          color: palette.primaryForeground,
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
                            ride.driverName,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ride.availableSeats}/${ride.totalSeats} seats left',
                            style: TextStyle(color: palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SmallActionButton(
                      icon: Icons.chat_bubble_outline,
                      onTap: () => context.go(AppRoutes.groupChatByTripId(ride.id)),
                    ),
                    const SizedBox(width: 8),
                    _SmallActionButton(
                      icon: Icons.arrow_forward_outlined,
                      onTap: () => context.go(AppRoutes.activeRideById(ride.id)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: palette.border),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.trip_origin,
                  iconColor: palette.secondary,
                  label: 'Origin',
                  value: ride.origin,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  iconColor: palette.textSecondary,
                  label: 'Destination',
                  value: ride.destination,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        title: 'Departure',
                        value: ride.departureLabel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniMetric(
                        title: 'Fare',
                        value: ride.priceLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UpdatesSection extends ConsumerWidget {
  const _UpdatesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(authUserProvider);
    final currentRide = ref.watch(currentDriverRideProvider).valueOrNull;
    final firstName = user?.fullName.split(RegExp(r'\s+')).first ?? 'User';

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
        if (role == UserRole.driver)
          _UpdateCard(
            icon: currentRide == null
                ? Icons.directions_car_outlined
                : Icons.people_alt_outlined,
            iconBg: palette.accent,
            title: currentRide == null
                ? 'No live ride yet'
                : 'Manage your current ride',
            subtitle: currentRide == null
                ? 'Create a ride to start receiving passenger applications.'
                : 'Open your live trip and review the passenger group.',
            highlight: true,
            actionLabel: currentRide == null ? 'Create Ride' : 'Open Ride',
            onAction: () => context.go(
              currentRide == null
                  ? AppRoutes.createRide
                  : AppRoutes.activeRideById(currentRide.id),
            ),
          )
        else
          _UpdateCard(
            icon: Icons.near_me,
            iconBg: palette.accent,
            title: 'Welcome, $firstName',
            subtitle: 'Browse available rides or pay quickly for your current trip.',
            highlight: true,
            actionLabel: 'Quick Pay',
            onAction: () => context.go(AppRoutes.payment),
          ),
        const SizedBox(height: 10),
        _UpdateCard(
          icon: Icons.person_outline,
          iconBg: palette.border,
          iconColor: palette.secondary,
          title: 'Profile and notifications',
          subtitle: 'Review your activity, alerts, and account preferences.',
          trailing: 'Open',
          onAction: null,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: palette.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.iconColor,
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
          color: highlight
              ? palette.accent.withValues(alpha: 0.35)
              : palette.border,
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
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
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
