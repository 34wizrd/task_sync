import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'diet_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table for the library of available foods
        await db.execute('''
          CREATE TABLE food_items(
            id TEXT PRIMARY KEY,
            name TEXT,
            calories INTEGER,
            updatedAt INTEGER
          )
        ''');

        // Table for the user's logged meals
        await db.execute('''
          CREATE TABLE meal_entries(
            id TEXT PRIMARY KEY,
            foodId TEXT,
            foodName TEXT,
            calories INTEGER,
            date INTEGER,
            updatedAt INTEGER
          )
        ''');

        // Outbox for syncing changes
        await db.execute('''
          CREATE TABLE outbox(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation TEXT,
            tableName TEXT,
            data TEXT,
            createdAt INTEGER
          )
        ''');
      },
    );
  }
}