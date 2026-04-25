import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      bottomNavigationBar: AppBottomNav(
        currentTab: AppBottomNavTab.alerts,
        role: role,
      ),
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
                      decoration: BoxDecoration(
                        color: palette.background,
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
    final palette = context.palette;

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
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                  const SizedBox(width: 4),
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
                  foregroundColor: palette.primaryForeground,
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
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted ? palette.secondary : Colors.transparent,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: palette.shadow.withValues(alpha: 0.22),
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
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 17,
                            color: palette.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              color: palette.textSecondary,
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
