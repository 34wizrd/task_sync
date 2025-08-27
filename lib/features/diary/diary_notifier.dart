import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/food_item_model.dart';
import '../../core/models/meal_entry_model.dart';
import '../../core/services/db_service.dart';

class DiaryNotifier extends ChangeNotifier {
  final DbService _dbService = DbService();
  final Uuid _uuid = Uuid();

  List<MealEntry> todaysEntries = [];
  int get totalCalories => todaysEntries.fold(0, (sum, item) => sum + item.calories);

  Future<void> loadTodaysEntries() async {
    final db = await _dbService.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 86400000 - 1; // 24 hours - 1 millisecond

    final maps = await db.query(
      'meal_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startOfDay, endOfDay],
    );

    todaysEntries = List.generate(maps.length, (i) => MealEntry.fromMap(maps[i]));
    notifyListeners();
  }

  Future<void> addMealEntry(FoodItem foodItem) async {
    final newEntry = MealEntry(
      id: _uuid.v4(),
      foodId: foodItem.id,
      foodName: foodItem.name,
      calories: foodItem.calories,
      date: DateTime.now(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final db = await _dbService.database;
    await db.insert('meal_entries', newEntry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    await _addToOutbox('CREATE', 'meal_entries', newEntry.toMap());
    await loadTodaysEntries();
  }

  Future<void> deleteMealEntry(String entryId) async {
    final db = await _dbService.database;

    // First, find the entry we are about to delete
    final List<Map<String, dynamic>> maps = await db.query(
      'meal_entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );

    if (maps.isNotEmpty) {
      // Add the delete operation to the outbox BEFORE deleting locally
      await _addToOutbox('DELETE', 'meal_entries', maps.first);
    }

    // Now, delete the entry from the local database
    await db.delete(
      'meal_entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );

    // Refresh the UI by reloading the entries and notifying listeners
    await loadTodaysEntries();
  }

  Future<void> updateMealEntry(MealEntry entry) async {
    final db = await _dbService.database;

    // Create an updated entry with a new timestamp
    final updatedEntry = MealEntry(
      id: entry.id,
      foodId: entry.foodId,
      foodName: entry.foodName,
      calories: entry.calories, // In a real app, this might be a new value
      date: entry.date,
      updatedAt: DateTime.now().millisecondsSinceEpoch, // Crucial: update the timestamp
    );

    // Update the record in the local database
    await db.update(
      'meal_entries',
      updatedEntry.toMap(),
      where: 'id = ?',
      whereArgs: [updatedEntry.id],
    );

    // Add the update operation to the outbox
    await _addToOutbox('UPDATE', 'meal_entries', updatedEntry.toMap());

    // Refresh the UI
    await loadTodaysEntries();
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