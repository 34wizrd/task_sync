class MealEntry {
  final String id;
  final String foodId;
  final String foodName;
  final int calories;
  final int createdAt;
  final int updatedAt;

  MealEntry({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.calories,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodId': foodId,
      'foodName': foodName,
      'calories': calories,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] ?? '',
      foodId: map['foodId'] ?? '',
      foodName: map['foodName'] ?? '',
      calories: map['calories']?.toInt() ?? 0,
      createdAt: map['createdAt']?.toInt() ?? 0,
      updatedAt: map['updatedAt']?.toInt() ?? 0,
    );
  }
}