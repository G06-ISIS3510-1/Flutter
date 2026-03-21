import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';
import '../../../../theme/app_colors.dart';

class ProfileViewData {
  const ProfileViewData({
    required this.fullName,
    required this.initials,
    required this.badgeLabel,
    required this.memberSince,
    required this.metrics,
    required this.contacts,
    required this.menuSections,
  });

  final String fullName;
  final String initials;
  final String badgeLabel;
  final String memberSince;
  final List<ProfileMetricData> metrics;
  final List<ProfileContactData> contacts;
  final List<ProfileMenuSectionData> menuSections;
}

class ProfileMetricData {
  const ProfileMetricData({
    required this.value,
    required this.label,
    required this.valueColor,
    this.route,
  });

  final String value;
  final String label;
  final Color valueColor;
  final String? route;
}

class ProfileContactData {
  const ProfileContactData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class ProfileMenuSectionData {
  const ProfileMenuSectionData({required this.title, required this.items});

  final String title;
  final List<ProfileMenuItemData> items;
}

class ProfileMenuItemData {
  const ProfileMenuItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? route;
}

final profileViewDataProvider = Provider<ProfileViewData>((ref) {
  final user = ref.watch(authUserProvider);
  final role = ref.watch(currentUserRoleProvider);

  final fullName = (user?.fullName.trim().isNotEmpty ?? false)
      ? user!.fullName.trim()
      : 'Wheels User';
  final email = user?.email ?? 'No email available';
  final roleLabel = _roleLabel(role);
  final badgeLabel = switch (role) {
    UserRole.admin => 'Platform Administrator',
    UserRole.driver => 'Driver Account',
    UserRole.passenger => 'Passenger Account',
  };

  return ProfileViewData(
    fullName: fullName,
    initials: _buildInitials(fullName),
    badgeLabel: badgeLabel,
    memberSince: 'Signed in as $email',
    metrics: [
      ProfileMetricData(
        value: roleLabel,
        label: 'Role',
        valueColor: AppColors.primary,
      ),
      const ProfileMetricData(
        value: 'Active',
        label: 'Status',
        valueColor: AppColors.accent,
      ),
      ProfileMetricData(
        value: user == null ? '--' : user.uid.substring(0, 6).toUpperCase(),
        label: 'User ID',
        valueColor: AppColors.warning,
      ),
      const ProfileMetricData(
        value: 'Firebase',
        label: 'Auth',
        valueColor: AppColors.secondary,
      ),
    ],
    contacts: [
      ProfileContactData(
        label: 'Email',
        value: email,
        icon: Icons.mail_outline_rounded,
      ),
      ProfileContactData(
        label: 'Role',
        value: roleLabel,
        icon: Icons.badge_outlined,
      ),
    ],
    menuSections: [
      ProfileMenuSectionData(
        title: 'Account',
        items: [
          const ProfileMenuItemData(
            title: 'Trust & Fairness',
            subtitle: 'View your reliability metrics',
            icon: Icons.star_border_rounded,
            route: AppRoutes.trust,
          ),
          const ProfileMenuItemData(
            title: 'Payment Methods',
            subtitle: 'Manage your payment options',
            icon: Icons.credit_card_outlined,
            route: AppRoutes.payment,
          ),
          const ProfileMenuItemData(
            title: 'Rewards & Points',
            subtitle: 'Redeem your rewards and points',
            icon: Icons.workspace_premium_outlined,
          ),
          if (role == UserRole.admin)
            const ProfileMenuItemData(
              title: 'Engagement Analytics',
              subtitle: 'Inspect user connection patterns',
              icon: Icons.bar_chart_rounded,
              route: AppRoutes.adminAnalytics,
            ),
        ],
      ),
      const ProfileMenuSectionData(
        title: 'Settings',
        items: [
          ProfileMenuItemData(
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            icon: Icons.notifications_none_rounded,
            route: AppRoutes.notifications,
          ),
          ProfileMenuItemData(
            title: 'Privacy & Security',
            subtitle: 'Control your privacy settings',
            icon: Icons.shield_outlined,
          ),
          ProfileMenuItemData(
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            icon: Icons.help_outline_rounded,
          ),
        ],
      ),
    ],
  );
});

final profileSummaryProvider = Provider<String>((ref) {
  final data = ref.watch(profileViewDataProvider);
  return '${data.fullName} is signed in and using the ${data.metrics.first.value.toLowerCase()} profile.';
});

final profileCompletionProvider = StateProvider<int>((ref) => 98);

String _buildInitials(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) {
    return 'WU';
  }

  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

String _roleLabel(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'Admin';
    case UserRole.driver:
      return 'Driver';
    case UserRole.passenger:
      return 'Passenger';
  }
}
