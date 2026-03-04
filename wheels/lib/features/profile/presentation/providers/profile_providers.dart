import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileSummaryProvider = Provider<String>((ref) => 'Profile is 70% complete');
final profileCompletionProvider = StateProvider<int>((ref) => 70);
