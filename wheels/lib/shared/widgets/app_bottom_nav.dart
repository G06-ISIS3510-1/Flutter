import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

enum AppBottomNavTab { home, middle, alerts, profile }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({required this.currentTab, required this.role, super.key});

  final AppBottomNavTab currentTab;
  final UserRole role;

  int get _selectedIndex => switch (currentTab) {
    AppBottomNavTab.home => 0,
    AppBottomNavTab.middle => 1,
    AppBottomNavTab.alerts => 2,
    AppBottomNavTab.profile => 3,
  };

  @override
  Widget build(BuildContext context) {
    final availableWidth =
        MediaQuery.sizeOf(context).width - (AppSpacing.m * 2);
    final navWidth = availableWidth > 430 ? 430.0 : availableWidth;
    final middleLabel = role == UserRole.driver ? 'Create' : 'Search';
    final middleIcon = role == UserRole.driver
        ? Icons.directions_car_outlined
        : Icons.search_outlined;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: navWidth,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  ),
                  boxShadow: AppShadows.md,
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  AppSpacing.xs,
                  AppSpacing.m,
                  AppSpacing.s,
                ),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  indicatorColor: Colors.transparent,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (index) =>
                      _onDestinationSelected(context, index),
                  destinations: <NavigationDestination>[
                    const NavigationDestination(
                      icon: Icon(Icons.place_outlined),
                      selectedIcon: _ActiveNavIcon(icon: Icons.place_outlined),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(middleIcon),
                      selectedIcon: _ActiveNavIcon(icon: middleIcon),
                      label: middleLabel,
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.notifications_none),
                      selectedIcon: _ActiveNavIcon(
                        icon: Icons.notifications_none,
                      ),
                      label: 'Alerts',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: _ActiveNavIcon(icon: Icons.person_outline),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        return;
      case 1:
        context.go(
          role == UserRole.driver ? AppRoutes.createRide : AppRoutes.rides,
        );
        return;
      case 2:
        context.go(AppRoutes.notifications);
        return;
      case 3:
        context.go(AppRoutes.profile);
        return;
      default:
        return;
    }
  }
}

class _ActiveNavIcon extends StatelessWidget {
  const _ActiveNavIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.primaryForeground, size: 18),
    );
  }
}
