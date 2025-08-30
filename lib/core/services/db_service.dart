import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbService {
  static const _dbName = 'diet_app.db';
  // UPDATE: Increment the version number. This is the trigger for the onUpgrade logic.
  static const _dbVersion = 2;

  // --- SINGLETON SETUP ---
  DbService._privateConstructor();
  static final DbService instance = DbService._privateConstructor();
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  // --- END SINGLETON SETUP ---

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      // ADDED: The onUpgrade callback is the key to handling migrations.
      onUpgrade: _onUpgrade,
      // ADDED: A best-practice callback to handle downgrades gracefully.
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  /// This method is called ONLY when the database is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
    // This batch ensures all creation statements run together as a single transaction.
    final batch = db.batch();
    _createV1Tables(batch);
    await batch.commit();
  }

  /// This method is called when the database version is increased.
  /// It allows you to update the schema without losing existing data.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final batch = db.batch();
    // Use a loop to apply all necessary migrations sequentially.
    for (var i = oldVersion + 1; i <= newVersion; i++) {
      // Use a switch for each version's specific migration script.
      switch (i) {
        case 2:
        // Example: In version 2, we decided to add a 'notes' column to meals.
        // batch.execute('''
        //   ALTER TABLE meal_entries ADD COLUMN notes TEXT
        // ''');
          break;
      // Add more cases for future versions (case 3, case 4, etc.)
      }
    }
    await batch.commit();
  }

  /// Contains all the table creation logic for the very first version.
  void _createV1Tables(Batch batch) {
    batch.execute('''
      CREATE TABLE food_items(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE meal_entries(
        id TEXT PRIMARY KEY,
        foodId TEXT NOT NULL,
        foodName TEXT NOT NULL,
        calories INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE outbox(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        tableName TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE sync_timestamps (
        id INTEGER PRIMARY KEY,
        lastSync INTEGER NOT NULL
      )
    ''');
  }
}