import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { passenger, driver }

final authStatusProvider = Provider<String>((ref) => 'Guest session');
final authStepProvider = StateProvider<int>((ref) => 0);
final currentUserRoleProvider = StateProvider<UserRole>((ref) => UserRole.driver);
final isDriverProvider = Provider<bool>(
  (ref) => ref.watch(currentUserRoleProvider) == UserRole.driver,
);
