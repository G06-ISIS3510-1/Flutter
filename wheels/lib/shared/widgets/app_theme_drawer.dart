import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../router/app_routes.dart';
import '../../theme/app_theme_palette.dart';
import '../../theme/theme_controller.dart';

class AppNavigationDrawer extends ConsumerStatefulWidget {
  const AppNavigationDrawer({super.key});

  @override
  ConsumerState<AppNavigationDrawer> createState() =>
      _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends ConsumerState<AppNavigationDrawer> {
  bool _appearanceExpanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final themeController = ref.watch(themeControllerProvider);
    final role = ref.watch(currentUserRoleProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.directions_car_filled_rounded,
                      color: palette.primaryForeground,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wheels',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Campus mobility, your way',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: palette.border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    onTap: () => _go(context, AppRoutes.dashboard),
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    onTap: () => _go(context, AppRoutes.profile),
                  ),
                  if (role == UserRole.driver)
                    _DrawerItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Wallet',
                      onTap: () => _go(context, AppRoutes.wallet),
                    ),
                  _DrawerItem(
                    icon: Icons.route_outlined,
                    label: 'My Rides',
                    onTap: () => _go(context, AppRoutes.rides),
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () => _go(context, AppRoutes.notifications),
                  ),
                  const SizedBox(height: 8),
                  _DrawerSection(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: _themeSubtitle(themeController.preference),
                    isExpanded: _appearanceExpanded,
                    onTap: () {
                      setState(() {
                        _appearanceExpanded = !_appearanceExpanded;
                      });
                    },
                    child: Column(
                      children: [
                        _ThemeOptionTile(
                          title: 'Automatic',
                          subtitle: 'Dark from 6:00 PM to 6:00 AM',
                          icon: Icons.schedule_rounded,
                          preference: ThemePreference.automatic,
                          currentPreference: themeController.preference,
                          onTap: () => ref
                              .read(themeControllerProvider)
                              .setPreference(ThemePreference.automatic),
                        ),
                        _ThemeOptionTile(
                          title: 'Light mode',
                          subtitle: 'Soft and clean daytime interface',
                          icon: Icons.light_mode_outlined,
                          preference: ThemePreference.light,
                          currentPreference: themeController.preference,
                          onTap: () => ref
                              .read(themeControllerProvider)
                              .setPreference(ThemePreference.light),
                        ),
                        _ThemeOptionTile(
                          title: 'Dark mode',
                          subtitle: 'Comfortable low-light appearance',
                          icon: Icons.dark_mode_outlined,
                          preference: ThemePreference.dark,
                          currentPreference: themeController.preference,
                          onTap: () => ref
                              .read(themeControllerProvider)
                              .setPreference(ThemePreference.dark),
                        ),
                      ],
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => _showComingSoon(context, 'Settings'),
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () => _showComingSoon(context, 'Help & Support'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }

  void _showComingSoon(BuildContext context, String label) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is coming soon.')));
  }

  static String _themeSubtitle(ThemePreference preference) {
    return switch (preference) {
      ThemePreference.automatic => 'Automatic schedule enabled',
      ThemePreference.light => 'Manual light mode active',
      ThemePreference.dark => 'Manual dark mode active',
    };
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: palette.textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onTap,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: palette.textSecondary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: child,
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.preference,
    required this.currentPreference,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ThemePreference preference;
  final ThemePreference currentPreference;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isSelected = preference == currentPreference;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? palette.accentSoft : palette.cardSecondary,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? palette.accent : palette.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? palette.accent : palette.card,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? palette.accentForeground
                        : palette.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? palette.accent : palette.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
