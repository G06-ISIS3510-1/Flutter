import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStatusProvider = Provider<String>((ref) => 'Guest session');
final authStepProvider = StateProvider<int>((ref) => 0);
