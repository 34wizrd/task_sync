// lib/src/data/base_repository.dart
import 'database_service.dart';

/// A model must be able to be created from a map and converted to a map.
/// This is a contract for our models.
abstract class BaseModel {
  final int? id;
  BaseModel({this.id});

  Map<String, dynamic> toMap();
  BaseModel copyWith({int? id});
}

/// Abstract class for a generic repository.
/// It provides basic CRUD operations.
/// T is the type of the model (e.g., ToDo, Category)
abstract class BaseRepository<T extends BaseModel> {
  final DatabaseService dbService = DatabaseService.instance;
  final String tableName;

  BaseRepository(this.tableName);

  /// Each repository must provide a way to convert a map from the DB
  /// into its specific model object.
  T fromMap(Map<String, dynamic> map);

  // --- GENERIC CRUD METHODS ---

  /// Create a new item in the database.
  Future<T> create(T item) async {
    try {
      final db = await dbService.database;
      final id = await db.insert(tableName, item.toMap());
      return item.copyWith(id: id) as T;
    } catch (e) {
      throw DatabaseException('Failed to create item: $e');
    }
  }

  /// Read all items from the table.
  Future<List<T>> readAll() async {
    try {
      final db = await dbService.database;
      final result = await db.query(tableName, orderBy: 'id DESC');
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to read all items: $e');
    }
  }

  /// Read a single item by ID.
  Future<T?> readById(int id) async {
    try {
      final db = await dbService.database;
      final result = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return fromMap(result.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to read item by ID: $e');
    }
  }

  /// Update an item in the database.
  Future<int> update(T item) async {
    try {
      if (item.id == null) {
        throw DatabaseException('Cannot update item without ID');
      }

      final db = await dbService.database;
      final rowsAffected = await db.update(
        tableName,
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (rowsAffected == 0) {
        throw DatabaseException('Item with ID ${item.id} not found');
      }

      return rowsAffected;
    } catch (e) {
      throw DatabaseException('Failed to update item: $e');
    }
  }

  /// Delete an item from the database by its ID.
  Future<int> delete(int id) async {
    try {
      final db = await dbService.database;
      final rowsAffected = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw DatabaseException('Item with ID $id not found');
      }

      return rowsAffected;
    } catch (e) {
      throw DatabaseException('Failed to delete item: $e');
    }
  }

  /// Check if an item exists by ID.
  Future<bool> exists(int id) async {
    try {
      final db = await dbService.database;
      final result = await db.query(
        tableName,
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw DatabaseException('Failed to check if item exists: $e');
    }
  }

  /// Count total items in the table.
  Future<int> count() async {
    try {
      final db = await dbService.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      return result.first['count'] as int;
    } catch (e) {
      throw DatabaseException('Failed to count items: $e');
    }
  }
}

/// Custom exception for database operations.
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}