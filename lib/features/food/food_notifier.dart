import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/food_item_model.dart';
import '../../core/services/db_service.dart';

class FoodNotifier extends ChangeNotifier {
  final DbService _dbService = DbService();
  final Uuid _uuid = Uuid();
  List<FoodItem> foodItems = [];

  Future<void> loadFoodItems() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('food_items');
    foodItems = List.generate(maps.length, (i) => FoodItem.fromMap(maps[i]));
    notifyListeners();
  }

  Future<void> addFoodItem(String name, int calories) async {
    final newFood = FoodItem(
      id: _uuid.v4(),
      name: name,
      calories: calories,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final db = await _dbService.database;
    await db.insert('food_items', newFood.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    await _addToOutbox('CREATE', '', newFood.toMap());
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