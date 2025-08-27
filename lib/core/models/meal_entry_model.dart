import 'package:flutter/foundation.dart';

@immutable
class MealEntry {
  final String id;
  final String foodId; // Foreign key to FoodItem
  final String foodName;
  final int calories;
  final DateTime date; // The date this was eaten
  final int updatedAt;

  const MealEntry({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.calories,
    required this.date,
    required this.updatedAt,
  });

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as String,
      foodId: map['foodId'] as String,
      foodName: map['foodName'] as String,
      calories: map['calories'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      updatedAt: map['updatedAt'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodId': foodId,
      'foodName': foodName,
      'calories': calories,
      'date': date.millisecondsSinceEpoch,
      'updatedAt': updatedAt,
    };
  }
}