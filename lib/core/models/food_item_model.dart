class FoodItem {
  final String id;
  final String name;
  final int calories;
  /// Unix epoch milliseconds
  final int updatedAt;

  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.updatedAt,
  });

  /// Create a modified copy.
  FoodItem copyWith({
    String? id,
    String? name,
    int? calories,
    int? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// SQLite/Firestore map helpers
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String,
      name: map['name'] as String,
      calories: (map['calories'] as num).toInt(),
      updatedAt: (map['updatedAt'] as num).toInt(),
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

  @override
  String toString() => 'FoodItem(id: $id, name: $name, calories: $calories, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodItem &&
        other.id == id &&
        other.name == name &&
        other.calories == calories &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, name, calories, updatedAt);
}
