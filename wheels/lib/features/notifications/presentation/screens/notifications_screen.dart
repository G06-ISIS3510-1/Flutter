import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../theme/app_colors.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const _BottomNav(currentIndex: 2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  const _NotificationsHeader(),
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(26),
                          topRight: Radius.circular(26),
                        ),
                      ),
                      padding: const EdgeInsets.only(top: 18),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _NotificationCard(
                              icon: Icons.near_me,
                              iconBg: Color(0xFF12D6A3),
                              title: 'Driver arriving soon',
                              subtitle:
                                  'Carlos is 3 minutes away from your pickup\nlocation',
                              time: 'Just now',
                              unread: true,
                              highlighted: true,
                            ),
                            SizedBox(height: 12),
                            _NotificationCard(
                              icon: Icons.workspace_premium_outlined,
                              iconBg: Color(0xFFF5A623),
                              title: 'You earned punctuality points!',
                              subtitle:
                                  '+5 points for being on time for your last ride',
                              time: '5 min ago',
                              unread: true,
                              highlighted: true,
                            ),
                            SizedBox(height: 12),
                            _NotificationCard(
                              icon: Icons.attach_money,
                              iconBg: Color(0xFF5B8BD9),
                              title: 'Payment reminder',
                              subtitle:
                                  "Don't forget to pay for your ride to Centro\nAndino",
                              time: '15 min ago',
                            ),
                            SizedBox(height: 12),
                            _NotificationCard(
                              icon: Icons.star_border,
                              iconBg: Color(0xFFF5A623),
                              title: 'New review received',
                              subtitle:
                                  'María gave you 5 stars! "Great passenger, very\npunctual"',
                              time: '1 hour ago',
                            ),
                            SizedBox(height: 12),
                            _NotificationCard(
                              icon: Icons.check_circle_outline,
                              iconBg: Color(0xFF12D6A3),
                              title: 'Ride completed',
                              subtitle:
                                  'Your ride to Usaquén has been successfully\ncompleted',
                              time: '3 hours ago',
                            ),
                            SizedBox(height: 12),
                            _NotificationCard(
                              icon: Icons.warning_amber_rounded,
                              iconBg: Color(0xFFFF5A5F),
                              title: 'Cancellation policy reminder',
                              subtitle:
                                  'Cancelling within 30 minutes may affect your\nreliability score',
                              time: 'Yesterday',
                            ),
                            SizedBox(height: 12),
                            _NotificationCard(
                              icon: Icons.schedule,
                              iconBg: Color(0xFF5B8BD9),
                              title: 'Ride scheduled',
                              subtitle:
                                  'Your ride tomorrow at 2:30 PM is confirmed',
                              time: 'Yesterday',
                            ),
                            SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.go(AppRoutes.dashboard),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, color: Colors.white, size: 24),
                  SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Stay updated with your rides',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                ),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;
  final bool unread;
  final bool highlighted;

  const _NotificationCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
    this.unread = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted ? const Color(0xFF4F8EF7) : Colors.transparent,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 17,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (unread)
            Positioned(
              top: 6,
              right: 4,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFF12D6A3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              label: 'Home',
              icon: Icons.location_on_outlined,
              selected: currentIndex == 0,
              onTap: () => context.go(AppRoutes.dashboard),
            ),
            _NavItem(
              label: 'Create',
              icon: Icons.directions_car_outlined,
              selected: currentIndex == 1,
              onTap: () => context.go(AppRoutes.createRide),
            ),
            _NavItem(
              label: 'Alerts',
              icon: Icons.notifications_none,
              selected: currentIndex == 2,
              onTap: () => context.go(AppRoutes.notifications),
            ),
            _NavItem(
              label: 'Profile',
              icon: Icons.person_outline,
              selected: currentIndex == 3,
              onTap: () => context.go(AppRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0B2346) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color:
                    selected ? const Color(0xFF0B2346) : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}