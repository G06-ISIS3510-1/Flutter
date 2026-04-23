import 'dart:collection';

class MemoryLruCache<K, V> {
  MemoryLruCache({required this.maxEntries})
    : assert(maxEntries > 0, 'maxEntries must be greater than zero.');

  final int maxEntries;
  final LinkedHashMap<K, V> _entries = LinkedHashMap<K, V>();

  V? get(K key) {
    final value = _entries.remove(key);
    if (value == null) {
      return null;
    }

    _entries[key] = value;
    return value;
  }

  void put(K key, V value) {
    _entries.remove(key);
    _entries[key] = value;

    if (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void remove(K key) {
    _entries.remove(key);
  }

  void clear() {
    _entries.clear();
  }

  bool containsKey(K key) {
    return _entries.containsKey(key);
  }
}
