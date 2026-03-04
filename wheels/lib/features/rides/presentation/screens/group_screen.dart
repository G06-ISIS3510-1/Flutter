import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../providers/rides_providers.dart';

class GroupScreen extends ConsumerWidget {
  const GroupScreen({required this.rideId, super.key});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideInfo = ref.watch(ridesStatusProvider);
    final chatInfo = ref.watch(chatStatusProvider);

    return AppScaffold(
      title: 'Group Ride',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Group Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          Text('Ride ID: $rideId'),
          const SizedBox(height: AppSpacing.s),
          Text('Ride status: $rideInfo'),
          const SizedBox(height: AppSpacing.s),
          Text('Chat: $chatInfo'),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Back to Rides',
            onPressed: () => context.go(AppRoutes.rides),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: 'Go to Reviews',
            isPrimary: false,
            onPressed: () => context.go(AppRoutes.reviews),
          ),
        ],
      ),
    );
  }
}
