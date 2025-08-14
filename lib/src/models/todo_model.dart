// lib/src/models/todo_model.dart
import '../data/base_repository.dart';

class ToDo extends BaseModel {
  final String title;
  final String? description;
  final bool isCompleted;
  final int? categoryId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dueDate;

  ToDo({
    super.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.categoryId,
    DateTime? createdAt,
    this.completedAt,
    this.dueDate,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory ToDo.fromMap(Map<String, dynamic> map) {
    return ToDo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      categoryId: map['categoryId'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : null,
    );
  }

  @override
  ToDo copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? categoryId,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? dueDate,
  }) {
    return ToDo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  @override
  String toString() {
    return 'ToDo{id: $id, title: $title, isCompleted: $isCompleted}';
  }
}