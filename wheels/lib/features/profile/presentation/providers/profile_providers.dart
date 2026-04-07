import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

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

  final rawName = user?.fullName.trim() ?? '';
  final shouldUseMockIdentity =
      rawName.isEmpty || rawName.toLowerCase() == 'dev access';

  final fullName = shouldUseMockIdentity ? 'Maria Gonzalez' : rawName;
  final email = user?.email.trim().isNotEmpty == true
      ? user!.email.trim()
      : 'm.gonzalez@uniandes.edu.co';

  final menuSections = <ProfileMenuSectionData>[
    ProfileMenuSectionData(
      title: 'Account',
      items: [
        const ProfileMenuItemData(
          title: 'Trust & Fairness',
          subtitle: 'View your reliability metrics',
          icon: Icons.star_border_rounded,
          route: AppRoutes.trust,
        ),
        ProfileMenuItemData(
          title: role == UserRole.driver ? 'Driver Wallet' : 'Payment Methods',
          subtitle: role == UserRole.driver
              ? 'View earnings and request withdrawals'
              : 'Manage your payment options',
          icon: role == UserRole.driver
              ? Icons.account_balance_wallet_outlined
              : Icons.credit_card_outlined,
          route: role == UserRole.driver ? AppRoutes.wallet : AppRoutes.payment,
        ),
        const ProfileMenuItemData(
          title: 'Rewards & Points',
          subtitle: 'Redeem your 142 points',
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
  ];

  return ProfileViewData(
    fullName: fullName,
    initials: _buildInitials(fullName),
    badgeLabel: _badgeLabel(role),
    memberSince: 'Member since Jan 2025',
    metrics: const [
      ProfileMetricData(
        value: '16',
        label: 'Rides',
        valueColor: AppColors.primary,
      ),
      ProfileMetricData(
        value: '98%',
        label: 'Score',
        valueColor: AppColors.accent,
      ),
      ProfileMetricData(
        value: '5',
        label: 'Rating',
        valueColor: AppColors.warning,
        route: AppRoutes.reviews,
      ),
      ProfileMetricData(
        value: '142',
        label: 'Points',
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
        value: _roleLabel(role),
        icon: Icons.badge_outlined,
      ),
    ],
    menuSections: menuSections,
  );
});

final profileSummaryProvider = Provider<String>((ref) {
  final data = ref.watch(profileViewDataProvider);
  return '${data.fullName} has ${data.metrics.first.value} rides and a ${data.metrics[2].value}-star rating.';
});

final profileCompletionProvider = StateProvider<int>((ref) => 98);

String _buildInitials(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) {
    return 'MG';
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

String _badgeLabel(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'Platform Administrator';
    case UserRole.driver:
      return 'Verified Driver';
    case UserRole.passenger:
      return 'Verified Student';
  }
}
