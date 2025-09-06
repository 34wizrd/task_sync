import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/food_item_model.dart';
import '../../core/services/db_service.dart';

/// A service class that encapsulates all database operations for food items.
/// This acts as a repository, providing a clean API to the rest of the app.
class FoodService {
  final DbService _dbService = DbService.instance;
  final Uuid _uuid = const Uuid();

  Future<List<FoodItem>> getFoodItems() async {
    final db = await _dbService.database;
    final maps = await db.query('food_items', orderBy: 'name COLLATE NOCASE ASC');
    return maps.map((m) => FoodItem.fromMap(m)).toList();
  }

  Future<FoodItem> addFoodItem(String name, int calories) async {
    final now = DateTime.now();
    final newFood = FoodItem(
      id: _uuid.v4(),
      name: name.trim(),
      calories: calories,
      updatedAt: now, servingSize: '', imagePath: '',
    );

    final db = await _dbService.database;
    await db.insert('food_items', newFood.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await _addToOutbox('CREATE', 'food_items', newFood.toMap());
    return newFood;
  }

  Future<FoodItem> updateFoodItem(FoodItem item) async {
    final db = await _dbService.database;
    final updatedItem = item.copyWith(updatedAt: DateTime.now());

    await db.update(
      'food_items',
      updatedItem.toMap(),
      where: 'id = ?',
      whereArgs: [updatedItem.id],
    );

    await _addToOutbox('UPDATE', 'food_items', updatedItem.toMap());
    return updatedItem;
  }

  Future<void> deleteFoodItem(String id) async {
    final db = await _dbService.database;

    final maps = await db.query('food_items', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      await _addToOutbox('DELETE', 'food_items', maps.first);
    }

    await db.delete('food_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPendingOutboxCount() async {
    final db = await _dbService.database;
    final res = await db.rawQuery('SELECT COUNT(*) AS c FROM outbox');
    return Sqflite.firstIntValue(res) ?? 0;
  }

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