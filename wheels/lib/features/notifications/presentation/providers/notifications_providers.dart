import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsMessageProvider = Provider<String>((ref) => '2 unread notifications');
final unreadNotificationsProvider = StateProvider<int>((ref) => 2);
