import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../models/saved_destination_model.dart';

class SavedDestinationsLocalDataSource {
  static const String _dbName = 'wheels_saved_destinations.db';
  static const int _dbVersion = 1;
  static const String _table = 'saved_destinations';

  Database? _db;
  final Map<String, StreamController<List<SavedDestinationModel>>> _controllers =
      <String, StreamController<List<SavedDestinationModel>>>{};

  Future<Database> _openDatabase() async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }

    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      '$dbPath/$_dbName',
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            lat REAL NOT NULL,
            lng REAL NOT NULL,
            created_at INTEGER NOT NULL,
            last_used_at INTEGER NOT NULL,
            use_count INTEGER NOT NULL,
            remote_id TEXT,
            thumbnail_url TEXT,
            pending_sync INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            UNIQUE(user_id, address)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_saved_destinations_recent '
          'ON $_table(user_id, last_used_at DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_saved_destinations_count '
          'ON $_table(user_id, use_count DESC)',
        );
      },
    );
    return _db!;
  }

  Stream<List<SavedDestinationModel>> watchDestinations(
    String userId, {
    SavedDestinationsLocalSort sort = SavedDestinationsLocalSort.recent,
  }) async* {
    final controller = _controllers.putIfAbsent(
      '$userId:${sort.name}',
      () => StreamController<List<SavedDestinationModel>>.broadcast(),
    );
    yield await loadDestinations(userId, sort: sort);
    yield* controller.stream;
  }

  Future<List<SavedDestinationModel>> loadDestinations(
    String userId, {
    SavedDestinationsLocalSort sort = SavedDestinationsLocalSort.recent,
    bool includeDeleted = false,
  }) async {
    final db = await _openDatabase();
    final rows = await db.query(
      _table,
      where: includeDeleted
          ? 'user_id = ?'
          : 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: sort == SavedDestinationsLocalSort.recent
          ? 'last_used_at DESC'
          : 'use_count DESC, last_used_at DESC',
    );
    return rows.map(SavedDestinationModel.fromSqlite).toList(growable: false);
  }

  Future<SavedDestinationModel?> loadDestinationById(
    String userId,
    int localId,
  ) async {
    final db = await _openDatabase();
    final rows = await db.query(
      _table,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, localId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return SavedDestinationModel.fromSqlite(rows.first);
  }

  Future<SavedDestinationModel> upsertDestination(
    SavedDestinationModel destination,
  ) async {
    final db = await _openDatabase();
    if (destination.localId == null) {
      await db.insert(
        _table,
        destination.toSqlite()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final rows = await db.query(
        _table,
        where: 'user_id = ? AND address = ?',
        whereArgs: [destination.userId, destination.address],
        limit: 1,
      );
      final saved = SavedDestinationModel.fromSqlite(rows.first);
      await _emitUser(destination.userId);
      return saved;
    }

    await db.update(
      _table,
      destination.toSqlite()..remove('id'),
      where: 'id = ? AND user_id = ?',
      whereArgs: [destination.localId, destination.userId],
    );
    final saved = await loadDestinationById(destination.userId, destination.localId!);
    await _emitUser(destination.userId);
    return saved!;
  }

  Future<void> markDestinationDeleted({
    required String userId,
    required int localId,
  }) async {
    final db = await _openDatabase();
    await db.update(
      _table,
      <String, Object?>{
        'is_deleted': 1,
        'pending_sync': 1,
        'last_used_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, userId],
    );
    await _emitUser(userId);
  }

  Future<List<SavedDestinationModel>> loadPendingSync(String userId) async {
    final db = await _openDatabase();
    final rows = await db.query(
      _table,
      where: 'user_id = ? AND pending_sync = 1',
      whereArgs: [userId],
      orderBy: 'last_used_at ASC',
    );
    return rows.map(SavedDestinationModel.fromSqlite).toList(growable: false);
  }

  Future<void> markSynced({
    required String userId,
    required int localId,
    String? remoteId,
  }) async {
    final db = await _openDatabase();
    await db.update(
      _table,
      <String, Object?>{
        'pending_sync': 0,
        'remote_id': remoteId,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, userId],
    );
    await _emitUser(userId);
  }

  Future<void> hardDelete({
    required String userId,
    required int localId,
  }) async {
    final db = await _openDatabase();
    await db.delete(
      _table,
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, userId],
    );
    await _emitUser(userId);
  }

  Future<void> _emitUser(String userId) async {
    for (final sort in SavedDestinationsLocalSort.values) {
      final key = '$userId:${sort.name}';
      final controller = _controllers[key];
      if (controller != null && !controller.isClosed) {
        controller.add(await loadDestinations(userId, sort: sort));
      }
    }
  }

  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
    await _db?.close();
    _db = null;
  }
}

enum SavedDestinationsLocalSort { recent, useCount }
