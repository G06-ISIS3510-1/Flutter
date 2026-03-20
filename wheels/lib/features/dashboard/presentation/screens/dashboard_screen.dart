import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../rides/presentation/models/ride_listing.dart';
import '../../../rides/presentation/providers/rides_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      backgroundColor: AppColors.background,
      maxScrollableWidth: 440,
      scrollableHeader: _DashboardHeader(
        firstName: firstName,
        email: user?.email ?? 'No email available',
      ),
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
              style: const TextStyle(color: AppColors.textSecondary),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.l,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _CircleIconButton(icon: Icons.menu),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
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
          const Row(
            children: [
              Expanded(child: _StatCard(value: 'Live', label: 'Session')),
              SizedBox(width: AppSpacing.s),
              Expanded(child: _StatCard(value: 'Firebase', label: 'Auth')),
              SizedBox(width: AppSpacing.s),
              Expanded(child: _StatCard(value: 'Wheels', label: 'App')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryForeground,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
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
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text(
                    'Campus rides',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned.fill(
            child: Center(
              child: Icon(Icons.near_me, color: AppColors.primary, size: 34),
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
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Current Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ride.status == 'in_progress' ? 'In Progress' : 'Open',
                        style: const TextStyle(
                          color: AppColors.accentHover,
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
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        ride.driverInitials,
                        style: const TextStyle(
                          color: AppColors.primaryForeground,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ride.availableSeats}/${ride.totalSeats} seats left',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
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
                Divider(color: Colors.black.withValues(alpha: 0.06)),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.trip_origin,
                  iconColor: AppColors.secondary,
                  label: 'Origin',
                  value: ride.origin,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.textSecondary,
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
                      child: _MiniMetric(title: 'Fare', value: ride.priceLabel),
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
    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(authUserProvider);
    final currentRide = ref.watch(currentDriverRideProvider).valueOrNull;
    final firstName = user?.fullName.split(RegExp(r'\s+')).first ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Updates',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (role == UserRole.driver)
          _UpdateCard(
            icon: currentRide == null
                ? Icons.directions_car_outlined
                : Icons.people_alt_outlined,
            iconBg: AppColors.accent,
            title: currentRide == null
                ? 'No live ride yet'
                : 'Your ride is visible now',
            subtitle: currentRide == null
                ? 'Create a ride so passengers can find and apply to it.'
                : '${currentRide.origin} to ${currentRide.destination} is already accepting passengers.',
            highlight: true,
            actionLabel: currentRide == null ? 'Create Ride' : 'View Ride',
            onAction: () => context.go(
              currentRide == null
                  ? AppRoutes.createRide
                  : AppRoutes.activeRideById(currentRide.id),
            ),
          )
        else
          _UpdateCard(
            icon: Icons.search_outlined,
            iconBg: AppColors.accent,
            title: 'Find your next ride',
            subtitle:
                '$firstName, browse active campus rides and apply with your current account.',
            highlight: true,
            actionLabel: 'Search Rides',
            onAction: () => context.go(AppRoutes.rides),
          ),
        const SizedBox(height: 10),
        _UpdateCard(
          icon: Icons.person_outline,
          iconBg: AppColors.border,
          iconColor: AppColors.secondary,
          title: 'Signed in account',
          subtitle: user?.email ?? 'No account data available.',
          trailing: role == UserRole.driver ? 'Driver' : 'Passenger',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight
              ? const Color(0xFFBBF7D0)
              : Colors.black.withValues(alpha: 0.06),
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
            child: Icon(icon, color: iconColor ?? Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            )
          else if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: AppColors.textSecondary,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
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
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: AppColors.primaryForeground),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.input;
    canvas.drawRect(Offset.zero & size, bg);

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
