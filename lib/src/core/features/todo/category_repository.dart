// lib/src/features/todo/data/repositories/category_repository.dart

import 'package:flutter/foundation.dart' hide Category;

import '../../../data/base_repository.dart';
import '../../../models/category_model.dart';

class CategoryRepository extends BaseRepository<Category> {
  // Pass the table name to the parent class.
  CategoryRepository() : super('categories');

  // Provide the specific implementation for fromMap.
  @override
  Category fromMap(Map<String, dynamic> map) {
    return Category.fromMap(map);
  }

  // --- CATEGORY-SPECIFIC METHODS ---

  /// Get all active categories.
  Future<List<Category>> getActive() async {
    try {
      final db = await dbService.database;
      final result = await db.query(
        tableName,
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get active categories: $e');
    }
  }

  /// Get all inactive categories.
  Future<List<Category>> getInactive() async {
    try {
      final db = await dbService.database;
      final result = await db.query(
        tableName,
        where: 'isActive = ?',
        whereArgs: [0],
        orderBy: 'name ASC',
      );
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get inactive categories: $e');
    }
  }

  /// Search categories by name.
  Future<List<Category>> searchByName(String query) async {
    try {
      final db = await dbService.database;
      final result = await db.query(
        tableName,
        where: 'name LIKE ? AND isActive = ?',
        whereArgs: ['%$query%', 1],
        orderBy: 'name ASC',
      );
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to search categories: $e');
    }
  }

  /// Check if category name already exists (for validation).
  Future<bool> nameExists(String name, {int? excludeId}) async {
    try {
      final db = await dbService.database;
      String whereClause = 'LOWER(name) = ?';
      List<dynamic> whereArgs = [name.toLowerCase()];

      if (excludeId != null) {
        whereClause += ' AND id != ?';
        whereArgs.add(excludeId);
      }

      final result = await db.query(
        tableName,
        columns: ['id'],
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw DatabaseException('Failed to check if category name exists: $e');
    }
  }

  /// Archive a category (set as inactive) instead of deleting.
  Future<int> archive(int categoryId) async {
    try {
      final db = await dbService.database;
      return await db.update(
        tableName,
        {'isActive': 0},
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    } catch (e) {
      throw DatabaseException('Failed to archive category: $e');
    }
  }

  /// Restore an archived category (set as active).
  Future<int> restore(int categoryId) async {
    try {
      final db = await dbService.database;
      return await db.update(
        tableName,
        {'isActive': 1},
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    } catch (e) {
      throw DatabaseException('Failed to restore category: $e');
    }
  }

  /// Get category with todo count.
  Future<Map<String, dynamic>?> getCategoryWithTodoCount(int categoryId) async {
    try {
      final db = await dbService.database;
      final result = await db.rawQuery('''
        SELECT c.*, COUNT(t.id) as todoCount
        FROM $tableName c
        LEFT JOIN todos t ON c.id = t.categoryId AND t.isCompleted = 0
        WHERE c.id = ?
        GROUP BY c.id
      ''', [categoryId]);

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get category with todo count: $e');
    }
  }

  /// Get all categories with their respective todo counts.
  Future<List<Map<String, dynamic>>> getCategoriesWithTodoCounts({
    bool activeOnly = true,
  }) async {
    try {
      final db = await dbService.database;
      String whereClause = activeOnly ? 'WHERE c.isActive = 1' : '';

      final result = await db.rawQuery('''
        SELECT c.*, 
               COUNT(CASE WHEN t.isCompleted = 0 THEN t.id END) as pendingTodoCount,
               COUNT(CASE WHEN t.isCompleted = 1 THEN t.id END) as completedTodoCount,
               COUNT(t.id) as totalTodoCount
        FROM $tableName c
        LEFT JOIN todos t ON c.id = t.categoryId
        $whereClause
        GROUP BY c.id
        ORDER BY c.name ASC
      ''');

      return result;
    } catch (e) {
      throw DatabaseException('Failed to get categories with todo counts: $e');
    }
  }

  /// Get categories ordered by most used (based on todo count).
  Future<List<Category>> getMostUsed({int limit = 10}) async {
    try {
      final db = await dbService.database;
      final result = await db.rawQuery('''
        SELECT c.*
        FROM $tableName c
        LEFT JOIN todos t ON c.id = t.categoryId
        WHERE c.isActive = 1
        GROUP BY c.id
        ORDER BY COUNT(t.id) DESC, c.name ASC
        LIMIT ?
      ''', [limit]);

      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get most used categories: $e');
    }
  }

  /// Get categories by color.
  Future<List<Category>> getByColor(String color) async {
    try {
      final db = await dbService.database;
      final result = await db.query(
        tableName,
        where: 'color = ? AND isActive = ?',
        whereArgs: [color, 1],
        orderBy: 'name ASC',
      );
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get categories by color: $e');
    }
  }

  /// Bulk activate/deactivate categories.
  Future<int> bulkUpdateStatus(List<int> categoryIds, bool isActive) async {
    try {
      final db = await dbService.database;
      final placeholders = List.filled(categoryIds.length, '?').join(',');

      return await db.rawUpdate('''
        UPDATE $tableName 
        SET isActive = ? 
        WHERE id IN ($placeholders)
      ''', [isActive ? 1 : 0, ...categoryIds]);
    } catch (e) {
      throw DatabaseException('Failed to bulk update category status: $e');
    }
  }

  /// Delete category only if it has no associated todos.
  Future<bool> safeDelete(int categoryId) async {
    try {
      final db = await dbService.database;

      // Check if category has any todos
      final todoCount = await db.rawQuery('''
        SELECT COUNT(*) as count FROM todos WHERE categoryId = ?
      ''', [categoryId]);

      final count = todoCount.first['count'] as int;

      if (count > 0) {
        if (kDebugMode) {
          print('Cannot delete category: $count todos are associated with it');
        }
        return false;
      }

      // Safe to delete
      await delete(categoryId);
      return true;
    } catch (e) {
      throw DatabaseException('Failed to safely delete category: $e');
    }
  }

  /// Get category usage statistics.
  Future<Map<String, dynamic>> getCategoryStats(int categoryId) async {
    try {
      final db = await dbService.database;
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as totalTodos,
          COUNT(CASE WHEN isCompleted = 1 THEN 1 END) as completedTodos,
          COUNT(CASE WHEN isCompleted = 0 THEN 1 END) as pendingTodos,
          COUNT(CASE WHEN dueDate IS NOT NULL AND dueDate < datetime('now') AND isCompleted = 0 THEN 1 END) as overdueTodos
        FROM todos 
        WHERE categoryId = ?
      ''', [categoryId]);

      if (result.isNotEmpty) {
        final stats = result.first;
        final total = stats['totalTodos'] as int;
        final completed = stats['completedTodos'] as int;

        return {
          'totalTodos': total,
          'completedTodos': completed,
          'pendingTodos': stats['pendingTodos'],
          'overdueTodos': stats['overdueTodos'],
          'completionRate': total > 0 ? (completed / total * 100).round() : 0,
        };
      }

      return {
        'totalTodos': 0,
        'completedTodos': 0,
        'pendingTodos': 0,
        'overdueTodos': 0,
        'completionRate': 0,
      };
    } catch (e) {
      throw DatabaseException('Failed to get category statistics: $e');
    }
  }
}