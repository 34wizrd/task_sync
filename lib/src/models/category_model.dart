import '../data/base_repository.dart';

class Category extends BaseModel {
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final bool isActive;

  Category({
    super.id,
    required this.name,
    this.description,
    this.color,
    this.icon,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      color: map['color'],
      icon: map['icon'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] == 1,
    );
  }

  @override
  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Category &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}