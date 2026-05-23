import 'dart:async';

import '../../domain/repositories/saved_destinations_repository.dart';

class SavedDestinationsSyncWorker {
  SavedDestinationsSyncWorker({
    required SavedDestinationsRepository repository,
    required Stream<bool> connectivityStream,
    required String Function() currentUserId,
  }) : _repository = repository,
       _connectivityStream = connectivityStream,
       _currentUserId = currentUserId;

  final SavedDestinationsRepository _repository;
  final Stream<bool> _connectivityStream;
  final String Function() _currentUserId;

  StreamSubscription<bool>? _subscription;
  bool _isSyncing = false;

  void start() {
    _subscription ??= _connectivityStream.listen((isOnline) async {
      if (!isOnline || _isSyncing) {
        return;
      }

      final userId = _currentUserId();
      if (userId.isEmpty) {
        return;
      }

      _isSyncing = true;
      try {
        await _repository.syncPending(userId);
      } finally {
        _isSyncing = false;
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
