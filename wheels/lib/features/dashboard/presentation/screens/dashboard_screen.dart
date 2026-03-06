import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../theme/app_colors.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final role = ref.watch(currentUserRoleProvider);

    return AppScaffold(
      title: 'Dashboard',
      showAppBar: false,
      backgroundColor: AppColors.background,
      maxScrollableWidth: 440,
      scrollableHeader: const _Header(),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _CurrentRideCard(),
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
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
/* ---------- UI widgets ---------- */

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
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
              _CircleIconButton(icon: Icons.menu, onTap: () {}),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'María',
                      style: TextStyle(
                        color: Colors.white,
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

          // ✅ Stats dentro del header como el mockup
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
    return Row(
      children: const [
        Expanded(
          child: _StatCard(value: '12', label: 'Rides'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '98%',
            label: 'Score', // ✅ mockup
            valueColor: AppColors.accent,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(value: '4.9', label: 'Rating'),
        ), // ✅ mockup
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatCard({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.18,
        ), // ✅ más visible como mockup
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.primaryForeground,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.1,
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
      height: 200, // ✅ más compacto como el mockup
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
                    '3 min away',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
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
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.accent, width: 4),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      color: Colors.black.withValues(alpha: 0.10),
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.near_me, color: AppColors.primary),
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
                color: AppColors.card,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 16,
                    color: Colors.black.withValues(alpha: 0.10),
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.near_me, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentRideCard extends StatelessWidget {
  const _CurrentRideCard();

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
                child: const Text(
                  'Active',
                  style: TextStyle(
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
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Center(
                  child: Text(
                    'CM',
                    style: TextStyle(
                      color: AppColors.primaryForeground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carlos Mendez',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                        SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Toyota Corolla 2020',
                          style: TextStyle(color: AppColors.textSecondary),
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
          Divider(color: Colors.black.withValues(alpha: 0.06)),
          const SizedBox(height: 10),
          const _InfoRow(
            icon: Icons.circle,
            iconColor: Color(0xFF3B82F6),
            label: 'Pickup',
            value: 'Campus Uniandes - Entrance Gate',
          ),
          const SizedBox(height: 10),
          const _InfoRow(
            icon: Icons.location_on_outlined,
            iconColor: AppColors.textSecondary,
            label: 'Destination',
            value: 'Centro Comercial Andino',
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Trip Progress',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '45%',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.45,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _MiniMetric(title: 'Distance', value: '4.2 km'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MiniMetric(title: 'Fare', value: '\$3,500'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdatesSection extends StatelessWidget {
  const _UpdatesSection();

  @override
  Widget build(BuildContext context) {
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
        _UpdateCard(
          icon: Icons.near_me,
          iconBg: AppColors.accent,
          title: 'Driver arriving soon',
          subtitle: 'Carlos is 3 minutes away from pickup',
          trailing: 'Now',
          highlight: true,
        ),
        const SizedBox(height: 10),
        _UpdateCard(
          icon: Icons.star_border,
          iconBg: AppColors.border,
          iconColor: AppColors.secondary,
          title: 'You earned punctuality points!',
          subtitle: '+5 points for being on time',
          trailing: '5m',
        ),
      ],
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String trailing;
  final bool highlight;

  const _UpdateCard({
    required this.icon,
    required this.iconBg,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.highlight = false,
  });

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
          Text(
            trailing,
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
  final String title;
  final String value;

  const _MiniMetric({required this.title, required this.value});

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
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

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
  final IconData icon;
  final VoidCallback onTap;

  const _SmallActionButton({required this.icon, required this.onTap});

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
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

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

class _BellButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BellButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: AppColors.primaryForeground,
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ✅ Bottom nav estilo mockup (círculo oscuro activo) */
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

    final pathPaint = Paint()
      ..color = const Color(0xFF94A3B8)
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
    for (final m in path.computeMetrics()) {
      double dist = 0;
      while (dist < m.length) {
        canvas.drawPath(m.extractPath(dist, dist + dash), pathPaint);
        dist += dash + gap;
      }
    }

    final dot = Paint()..color = AppColors.secondary;
    canvas.drawCircle(Offset(size.width * 0.27, size.height * 0.78), 5, dot);

    final dot2 = Paint()..color = AppColors.accent;
    canvas.drawCircle(Offset(size.width * 0.58, size.height * 0.48), 8, dot2);

    final dot3 = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(size.width * 0.83, size.height * 0.36), 6, dot3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
