import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  const ConnectivityService();

  Future<bool> hasConnection() async {
    final results = await Connectivity().checkConnectivity();
    return _isConnected(results);
  }

  Stream<bool> watchConnection() {
    return Connectivity().onConnectivityChanged.map(_isConnected).distinct();
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return const ConnectivityService();
});

final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.hasConnection();
  yield* service.watchConnection();
});
