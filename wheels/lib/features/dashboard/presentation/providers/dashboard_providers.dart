import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardSummaryProvider = Provider<String>((ref) => 'Dashboard overview');
final dashboardCardCountProvider = StateProvider<int>((ref) => 3);
