import 'dart:collection';

class SavedDestinationsDistanceCache {
  SavedDestinationsDistanceCache({this.capacity = 64})
    : assert(capacity > 0, 'capacity must be greater than zero.');

  final int capacity;
  final LinkedHashMap<String, double> _entries = LinkedHashMap<String, double>();

  double? get({
    required int destinationId,
    required double latitude,
    required double longitude,
  }) {
    final key = _buildKey(
      destinationId: destinationId,
      latitude: latitude,
      longitude: longitude,
    );
    final value = _entries.remove(key);
    if (value == null) {
      return null;
    }
    _entries[key] = value;
    return value;
  }

  void put({
    required int destinationId,
    required double latitude,
    required double longitude,
    required double distanceKm,
  }) {
    final key = _buildKey(
      destinationId: destinationId,
      latitude: latitude,
      longitude: longitude,
    );
    _entries.remove(key);
    _entries[key] = distanceKm;
    if (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void invalidateDestination(int destinationId) {
    final prefix = '$destinationId:';
    _entries.removeWhere((key, _) => key.startsWith(prefix));
  }

  void clear() {
    _entries.clear();
  }

  String _buildKey({
    required int destinationId,
    required double latitude,
    required double longitude,
  }) {
    final latBucket = (latitude * 1000).round();
    final lngBucket = (longitude * 1000).round();
    return '$destinationId:$latBucket:$lngBucket';
  }
}
