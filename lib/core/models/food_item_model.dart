class FoodItem {
  final String id;
  final String name;
  final int calories;
  final String servingSize;
  final String imagePath;
  final DateTime updatedAt;

  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.servingSize,
    required this.imagePath,
    required this.updatedAt,
  });

  String get details => '$servingSize · $calories cal';

  /// Convert a map into a FoodItem
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String,
      name: map['name'] as String,
      calories: map['calories'] as int,
      servingSize: map['servingSize'] as String,
      imagePath: map['imagePath'] as String,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Convert this FoodItem into a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'servingSize': servingSize,
      'imagePath': imagePath,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this FoodItem with some fields changed
  FoodItem copyWith({
    String? id,
    String? name,
    int? calories,
    String? servingSize,
    String? imagePath,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      servingSize: servingSize ?? this.servingSize,
      imagePath: imagePath ?? this.imagePath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
