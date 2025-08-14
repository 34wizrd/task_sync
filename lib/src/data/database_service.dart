import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/todo_model.dart';

class DatabaseService {
  // Use a singleton pattern to ensure only one instance of the database is ever created.
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todos.db');
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Create the database table
  Future _createDB(Database db, int version) async {
    // Use TEXT for title and INTEGER for id and boolean values
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        isCompleted INTEGER NOT NULL
      )
    ''');
  }

  // --- CRUD Operations ---

  // Create (Insert) a new to-do
  Future<ToDo> create(ToDo todo) async {
    final db = await instance.database;
    // The `insert` method returns the id of the new row.
    final id = await db.insert('todos', todo.toMap());
    // We create a new ToDo object with the returned id.
    return ToDo(id: id, title: todo.title, isCompleted: todo.isCompleted);
  }

  // Read all to-dos
  Future<List<ToDo>> readAllTodos() async {
    final db = await instance.database;
    final result = await db.query('todos', orderBy: 'id DESC');
    return result.map((json) => ToDo.fromMap(json)).toList();
  }

  // Update a to-do
  Future<int> update(ToDo todo) async {
    final db = await instance.database;
    return db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  // Delete a to-do
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close the database connection (important for resource management)
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}