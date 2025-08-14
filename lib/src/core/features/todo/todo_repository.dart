// lib/src/features/todo/data/repositories/todo_repository.dart
import '../../../data/base_repository.dart';
import '../../../models/todo_model.dart';

class ToDoRepository extends BaseRepository<ToDo> {
  ToDoRepository() : super('todos');

  @override
  ToDo fromMap(Map<String, dynamic> map) {
    return ToDo.fromMap(map);
  }

  // --- CUSTOM METHODS ---

  /// Get all todos by category ID.
  Future<List<ToDo>> getByCategory(int categoryId) async {
    try {
      final db = await dbService.database;
      final result = await db.query(
        tableName,
        where: 'categoryId = ?',
        whereArgs: [categoryId],
        orderBy: 'createdAt DESC',
      );
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get todos by category: $e');
    }
  }

  /// Get all completed todos.
  Future<List<ToDo>> getCompleted() async {
    try {
      final db = await dbService.database;
      final result = await db.query(
        tableName,
        where: 'isCompleted = ?',
        whereArgs: [1],
        orderBy: 'completedAt DESC',
      );
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get completed todos: $e');
    }
  }

  /// Get all pending todos.
  Future<List<ToDo>> getPending() async {
    try {
      final db = await dbService.database;
      final result = await db.query(
        tableName,
        where: 'isCompleted = ?',
        whereArgs: [0],
        orderBy: 'createdAt DESC',
      );
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get pending todos: $e');
    }
  }

  /// Get todos due by a specific date.
  Future<List<ToDo>> getDueByDate(DateTime date) async {
    try {
      final db = await dbService.database;
      final dateStr = date.toIso8601String().split('T')[0]; // Get date part only
      final result = await db.query(
        tableName,
        where: 'dueDate LIKE ? AND isCompleted = ?',
        whereArgs: ['$dateStr%', 0],
        orderBy: 'dueDate ASC',
      );
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get todos due by date: $e');
    }
  }

  /// Mark a todo as completed.
  Future<int> markAsCompleted(int todoId) async {
    try {
      final db = await dbService.database;
      return await db.update(
        tableName,
        {
          'isCompleted': 1,
          'completedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [todoId],
      );
    } catch (e) {
      throw DatabaseException('Failed to mark todo as completed: $e');
    }
  }

  /// Mark a todo as pending.
  Future<int> markAsPending(int todoId) async {
    try {
      final db = await dbService.database;
      return await db.update(
        tableName,
        {
          'isCompleted': 0,
          'completedAt': null,
        },
        where: 'id = ?',
        whereArgs: [todoId],
      );
    } catch (e) {
      throw DatabaseException('Failed to mark todo as pending: $e');
    }
  }

  /// Search todos by title or description.
  Future<List<ToDo>> search(String query) async {
    try {
      final db = await dbService.database;
      final result = await db.query(
        tableName,
        where: 'title LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'createdAt DESC',
      );
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to search todos: $e');
    }
  }

  /// Get todos with pagination.
  Future<List<ToDo>> getPaginated({
    int page = 1,
    int limit = 20,
    bool completedOnly = false,
  }) async {
    try {
      final db = await dbService.database;
      final offset = (page - 1) * limit;

      String? whereClause;
      List<dynamic>? whereArgs;

      if (completedOnly) {
        whereClause = 'isCompleted = ?';
        whereArgs = [1];
      }

      final result = await db.query(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'createdAt DESC',
        limit: limit,
        offset: offset,
      );
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get paginated todos: $e');
    }
  }
}