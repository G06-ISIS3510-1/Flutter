import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewsSummaryProvider = Provider<String>((ref) => 'No reviews yet');
final reviewsCountProvider = StateProvider<int>((ref) => 0);
