import 'package:flutter_riverpod/flutter_riverpod.dart';

final ridesStatusProvider = Provider<String>((ref) => 'Ride search ready');
final activeRideCountProvider = StateProvider<int>((ref) => 1);
