import 'package:flutter_riverpod/flutter_riverpod.dart';

final trustStatusProvider = Provider<String>((ref) => 'Trust checks pending');
final trustPendingStepsProvider = StateProvider<int>((ref) => 1);
