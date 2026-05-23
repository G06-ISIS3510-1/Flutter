import 'package:sqflite/sqflite.dart';

import '../models/ride_history_model.dart';

class RideHistoryLocalDataSource {
  static const String _dbName = 'wheels_ride_history.db';
  static const int _dbVersion = 1;
  static const String _table = 'ride_history';

  Database? _db;

  Future<Database> _openDatabase() async {
    if (_db != null && _db!.isOpen) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      '$dbPath/$_dbName',
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            rideId     TEXT    NOT NULL,
            userId     TEXT    NOT NULL,
            userRole   TEXT    NOT NULL,
            driverName TEXT    NOT NULL,
            origin     TEXT    NOT NULL,
            destination TEXT   NOT NULL,
            departureAt INTEGER NOT NULL,
            pricePerSeat INTEGER NOT NULL,
            status     TEXT    NOT NULL,
            totalSeats INTEGER NOT NULL,
            savedAt    INTEGER NOT NULL,
            UNIQUE(rideId, userId)
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<RideHistoryModel>> loadHistory(String userId) async {
    final db = await _openDatabase();
    final rows = await db.query(
      _table,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'departureAt DESC',
    );
    return rows.map(RideHistoryModel.fromSqlite).toList();
  }

  Future<void> saveHistory(List<RideHistoryModel> entries) async {
    if (entries.isEmpty) return;
    final db = await _openDatabase();
    final batch = db.batch();
    for (final entry in entries) {
      batch.insert(
        _table,
        entry.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearHistory(String userId) async {
    final db = await _openDatabase();
    await db.delete(_table, where: 'userId = ?', whereArgs: [userId]);
  }
}
