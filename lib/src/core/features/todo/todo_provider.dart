import 'package:flutter/foundation.dart' hide Category;
import 'package:task_sync/src/core/features/todo/todo_repository.dart';
import '../../../models/todo_model.dart';
import '../../../models/category_model.dart';
import 'category_repository.dart';

class ToDoProvider extends ChangeNotifier {
  // The provider now uses repositories, not a direct database service.
  final ToDoRepository _todoRepo = ToDoRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  // State
  List<ToDo> _todos = [];
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  // Filter states
  bool _showCompletedOnly = false;
  bool _showPendingOnly = false;
  String _searchQuery = '';

  // Getters for the UI
  List<ToDo> get todos => List.unmodifiable(_filteredTodos);
  List<Category> get categories => List.unmodifiable(_categories);
  Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showCompletedOnly => _showCompletedOnly;
  bool get showPendingOnly => _showPendingOnly;
  String get searchQuery => _searchQuery;

  // Filtered todos based on current filters
  List<ToDo> get _filteredTodos {
    List<ToDo> filtered = List.from(_todos);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((todo) =>
      todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (todo.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    // Apply completion status filters
    if (_showCompletedOnly) {
      filtered = filtered.where((todo) => todo.isCompleted).toList();
    } else if (_showPendingOnly) {
      filtered = filtered.where((todo) => !todo.isCompleted).toList();
    }

    return filtered;
  }

  // Statistics getters
  int get totalTodos => _todos.length;
  int get completedTodos => _todos.where((todo) => todo.isCompleted).length;
  int get pendingTodos => _todos.where((todo) => !todo.isCompleted).length;
  double get completionRate => totalTodos > 0 ? (completedTodos / totalTodos * 100) : 0.0;

  ToDoProvider() {
    // When the provider starts, load all necessary data.
    loadInitialData();
  }

  // --- INITIALIZATION ---

  Future<void> loadInitialData() async {
    await _executeWithLoading(() async {
      // Fetch all active categories
      _categories = await _categoryRepo.getActive();

      // If categories exist, select and load the first one
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
        await _fetchTodosForSelectedCategory();
      }
    });
  }

  Future<void> refreshData() async {
    _error = null;
    await loadInitialData();
  }

  // --- CATEGORY MANAGEMENT ---

  Future<void> selectCategory(Category category) async {
    if (_selectedCategory?.id != category.id) {
      _selectedCategory = category;
      await _fetchTodosForSelectedCategory();
    }
  }

  Future<void> fetchTodosForCategory(int categoryId) async {
    final category = _categories.firstWhere(
          (cat) => cat.id == categoryId,
      orElse: () => throw Exception('Category not found'),
    );
    await selectCategory(category);
  }

  Future<void> _fetchTodosForSelectedCategory() async {
    if (_selectedCategory != null) {
      await _executeWithLoading(() async {
        _todos = await _todoRepo.getByCategory(_selectedCategory!.id!);
      });
    }
  }

  Future<void> addCategory(String name, {String? description, String? color, String? icon}) async {
    try {
      // Check if name already exists
      final nameExists = await _categoryRepo.nameExists(name);
      if (nameExists) {
        throw Exception('Category name "$name" already exists');
      }

      final newCategory = Category(
        name: name,
        description: description,
        color: color,
        icon: icon,
      );

      final created = await _categoryRepo.create(newCategory);
      _categories.add(created);
      _categories.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();

      // Auto-select the new category
      await selectCategory(created);
    } catch (e) {
      _setError('Failed to add category: $e');
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      // Check if name already exists (excluding current category)
      final nameExists = await _categoryRepo.nameExists(category.name, excludeId: category.id);
      if (nameExists) {
        throw Exception('Category name "${category.name}" already exists');
      }

      await _categoryRepo.update(category);
      final index = _categories.indexWhere((cat) => cat.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        _categories.sort((a, b) => a.name.compareTo(b.name));

        // Update selected category if it's the one being updated
        if (_selectedCategory?.id == category.id) {
          _selectedCategory = category;
        }

        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(Category category) async {
    try {
      final canDelete = await _categoryRepo.safeDelete(category.id!);
      if (!canDelete) {
        throw Exception('Cannot delete category: it contains todos');
      }

      _categories.removeWhere((cat) => cat.id == category.id);

      // If deleted category was selected, select first available category
      if (_selectedCategory?.id == category.id) {
        _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
        await _fetchTodosForSelectedCategory();
      } else {
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to delete category: $e');
    }
  }

  // --- TODO MANAGEMENT ---

  Future<void> addTodo(String title, {
    String? description,
    DateTime? dueDate,
    int? categoryId,
  }) async {
    try {
      final targetCategoryId = categoryId ?? _selectedCategory?.id;
      if (targetCategoryId == null) {
        throw Exception('No category selected');
      }

      final newTodo = ToDo(
        title: title,
        description: description,
        categoryId: targetCategoryId,
        dueDate: dueDate,
      );

      final created = await _todoRepo.create(newTodo);

      // Add to current list if it belongs to selected category
      if (targetCategoryId == _selectedCategory?.id) {
        _todos.insert(0, created); // Add to beginning for most recent first
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to add todo: $e');
    }
  }

  Future<void> updateTodo(ToDo todo) async {
    try {
      await _todoRepo.update(todo);
      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = todo;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update todo: $e');
    }
  }

  Future<void> toggleTodoStatus(ToDo todo) async {
    try {
      if (todo.isCompleted) {
        // Mark as pending
        await _todoRepo.markAsPending(todo.id!);
        final updated = todo.copyWith(
          isCompleted: false,
          completedAt: null,
        );
        final index = _todos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          _todos[index] = updated;
          notifyListeners();
        }
      } else {
        // Mark as completed
        await _todoRepo.markAsCompleted(todo.id!);
        final updated = todo.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        final index = _todos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          _todos[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _setError('Failed to toggle todo status: $e');
    }
  }

  Future<void> removeTodo(ToDo todo) async {
    try {
      await _todoRepo.delete(todo.id!);
      _todos.removeWhere((t) => t.id == todo.id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove todo: $e');
    }
  }

  Future<void> bulkMarkAsCompleted(List<ToDo> todos) async {
    try {
      for (final todo in todos) {
        if (!todo.isCompleted) {
          await _todoRepo.markAsCompleted(todo.id!);
          final index = _todos.indexWhere((t) => t.id == todo.id);
          if (index != -1) {
            _todos[index] = todo.copyWith(
              isCompleted: true,
              completedAt: DateTime.now(),
            );
          }
        }
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to bulk mark todos as completed: $e');
    }
  }

  Future<void> bulkDelete(List<ToDo> todos) async {
    try {
      for (final todo in todos) {
        await _todoRepo.delete(todo.id!);
        _todos.removeWhere((t) => t.id == todo.id);
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to bulk delete todos: $e');
    }
  }

  // --- FILTERING & SEARCH ---

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void setShowCompletedOnly(bool value) {
    _showCompletedOnly = value;
    if (value) _showPendingOnly = false;
    notifyListeners();
  }

  void setShowPendingOnly(bool value) {
    _showPendingOnly = value;
    if (value) _showCompletedOnly = false;
    notifyListeners();
  }

  void clearFilters() {
    _showCompletedOnly = false;
    _showPendingOnly = false;
    _searchQuery = '';
    notifyListeners();
  }

  // --- SPECIALIZED QUERIES ---

  Future<List<ToDo>> getTodosNoDueDate() async {
    try {
      if (_selectedCategory == null) return [];
      final allTodos = await _todoRepo.getByCategory(_selectedCategory!.id!);
      return allTodos.where((todo) => todo.dueDate == null).toList();
    } catch (e) {
      _setError('Failed to get todos due today: $e');
      return [];
    }
  }

  Future<List<ToDo>> getTodosDueToday() async {
    try {
      final today = DateTime.now();
      return await _todoRepo.getDueByDate(today);
    } catch (e) {
      _setError('Failed to get todos due today: $e');
      return [];
    }
  }

  Future<List<ToDo>> getOverdueTodos() async {
    try {
      if (_selectedCategory == null) return [];
      final allTodos = await _todoRepo.getByCategory(_selectedCategory!.id!);
      final now = DateTime.now();
      return allTodos.where((todo) =>
      todo.dueDate != null &&
          todo.dueDate!.isBefore(now) &&
          !todo.isCompleted
      ).toList();
    } catch (e) {
      _setError('Failed to get overdue todos: $e');
      return [];
    }
  }

  // --- UTILITY METHODS ---

  Future<void> _executeWithLoading(Future<void> Function() operation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await operation();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    if (kDebugMode) {
      print('ToDoProvider Error: $error');
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // --- CLEANUP ---

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  // --- DEBUG HELPERS ---

  void debugPrintState() {
    if (kDebugMode) {
      print('=== ToDoProvider State ===');
      print('Categories: ${_categories.length}');
      print('Selected Category: ${_selectedCategory?.name}');
      print('Todos: ${_todos.length}');
      print('Filtered Todos: ${_filteredTodos.length}');
      print('Completed: $completedTodos');
      print('Pending: $pendingTodos');
      print('Completion Rate: ${completionRate.toStringAsFixed(1)}%');
      print('Is Loading: $_isLoading');
      print('Error: $_error');
      print('========================');
    }
  }
}