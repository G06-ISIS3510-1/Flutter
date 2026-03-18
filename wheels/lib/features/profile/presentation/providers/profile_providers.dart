import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

const _mockProfileData = ProfileViewData(
  fullName: 'Maria Gonzalez',
  initials: 'MG',
  badgeLabel: 'Verified Student',
  memberSince: 'Member since Jan 2025',
  metrics: [
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
      value: 'm.gonzalez@uniandes.edu.co',
      icon: Icons.mail_outline_rounded,
    ),
    ProfileContactData(
      label: 'Phone',
      value: '+57 300 123 4567',
      icon: Icons.phone_outlined,
    ),
  ],
  menuSections: [
    ProfileMenuSectionData(
      title: 'Account',
      items: [
        ProfileMenuItemData(
          title: 'Trust & Fairness',
          subtitle: 'View your reliability metrics',
          icon: Icons.star_border_rounded,
          route: AppRoutes.trust,
        ),
        ProfileMenuItemData(
          title: 'Payment Methods',
          subtitle: 'Manage your payment options',
          icon: Icons.credit_card_outlined,
          route: AppRoutes.payment,
        ),
        ProfileMenuItemData(
          title: 'Rewards & Points',
          subtitle: 'Redeem your 142 points',
          icon: Icons.workspace_premium_outlined,
        ),
      ],
    ),
    ProfileMenuSectionData(
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

final profileViewDataProvider = Provider<ProfileViewData>(
  (ref) => _mockProfileData,
);

final profileSummaryProvider = Provider<String>((ref) {
  final data = ref.watch(profileViewDataProvider);
  return '${data.fullName} has ${data.metrics.last.value} points and ${data.metrics.first.value} rides.';
});

final profileCompletionProvider = StateProvider<int>((ref) => 98);
