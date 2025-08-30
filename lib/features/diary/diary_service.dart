import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/food_item_model.dart';
import '../../core/models/meal_entry_model.dart';
import '../../core/services/db_service.dart';

/// A service class that encapsulates all database operations for meal entries.
/// This acts as the repository for the diary feature.
class DiaryService {
  final DbService _dbService = DbService.instance;
  final Uuid _uuid = const Uuid();

  Future<List<MealEntry>> getTodaysEntries() async {
    final db = await _dbService.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

    final maps = await db.query(
      'meal_entries',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => MealEntry.fromMap(m)).toList();
  }

  /// Creates a new meal entry from a food item.
  Future<MealEntry> addMealEntry(FoodItem foodItem) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final newEntry = MealEntry(
      id: _uuid.v4(),
      foodId: foodItem.id,
      foodName: foodItem.name,
      calories: foodItem.calories,
      createdAt: now,
      updatedAt: now,
    );

    final db = await _dbService.database;
    await db.insert('meal_entries', newEntry.toMap());
    await _addToOutbox('CREATE', 'meal_entries', newEntry.toMap());

    return newEntry;
  }

  /// Deletes a meal entry by its unique ID.
  Future<void> deleteMealEntry(String id) async {
    final db = await _dbService.database;
    final maps = await db.query('meal_entries', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      await _addToOutbox('DELETE', 'meal_entries', maps.first);
    }

    await db.delete('meal_entries', where: 'id = ?', whereArgs: [id]);
  }

  /// Adds an operation to the outbox for background synchronization.
  Future<void> _addToOutbox(String operation, String table, Map<String, dynamic> data) async {
    final db = await _dbService.database;
    await db.insert('outbox', {
      'operation': operation,
      'tableName': table,
      'data': jsonEncode(data),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}