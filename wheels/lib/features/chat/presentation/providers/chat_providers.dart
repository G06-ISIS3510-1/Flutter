import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatStatusProvider = Provider<String>((ref) => 'Group chat enabled');
final chatMessageCountProvider = StateProvider<int>((ref) => 4);
