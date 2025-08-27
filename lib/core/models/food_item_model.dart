import 'package:flutter/foundation.dart';

@immutable
class FoodItem {
  final String id;
  final String name;
  final int calories; // Calories per serving
  final int updatedAt;

  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.updatedAt,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String,
      name: map['name'] as String,
      calories: map['calories'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'updatedAt': updatedAt,
    };
  }
}