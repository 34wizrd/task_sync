import 'package:sqflite/sqflite.dart';

import 'db_service.dart';

/// A service dedicated to managing the last sync timestamp.
class TimestampService {
  // --- SINGLETON SETUP ---
  TimestampService._privateConstructor();
  static final TimestampService instance = TimestampService._privateConstructor();
  // --- END SINGLETON SETUP ---

  // CORRECTED: Use the singleton instance.
  final DbService _dbService = DbService.instance;

  /// Gets the last sync timestamp from the database. Returns 0 if none exists.
  Future<int> getLastSyncTimestamp() async {
    final db = await _dbService.database;
    final res = await db.query('sync_timestamps', limit: 1);
    if (res.isNotEmpty) {
      return res.first['lastSync'] as int;
    }
    return 0; // Default to 0 if no timestamp has been saved yet
  }

  /// Updates the last sync timestamp to the current time.
  Future<void> updateLastSyncTimestamp() async {
    final db = await _dbService.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    // Use `insert` with replace conflict algorithm to either create or update the single row.
    await db.insert(
      'sync_timestamps',
      {'id': 1, 'lastSync': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}