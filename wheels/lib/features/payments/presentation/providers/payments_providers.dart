import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentsStatusProvider = Provider<String>((ref) => 'Payment methods available');
final savedPaymentMethodsProvider = StateProvider<int>((ref) => 2);
