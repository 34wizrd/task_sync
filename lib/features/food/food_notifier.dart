import '../../core/base/base_notifier.dart';
import '../../core/models/food_item_model.dart';
import '../../core/network/sync_notifier.dart';
import 'food_service.dart';

/// Manages the state for the food screen.
///
/// This notifier delegates all data persistence and business logic to the [FoodService]
/// and focuses solely on managing the UI state, such as the list of food items,
/// loading status, search queries, and errors.
///

class FoodNotifier extends BaseNotifier {
  // Dependencies are required and provided via constructor injection.
  FoodNotifier({
    required FoodService foodService,
    required SyncNotifier syncNotifier,
  })  : _foodService = foodService,
        _syncNotifier = syncNotifier {
    loadFoods();
  }

  final FoodService _foodService;
  final SyncNotifier _syncNotifier;

  List<FoodItem> _foodItems = [];
  String _searchQuery = '';

  /// The main list of items for the UI, filtered by the search query.
  List<FoodItem> get foodItems {
    if (_searchQuery.isEmpty) {
      return _foodItems;
    }
    final q = _searchQuery.toLowerCase();
    return _foodItems.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  /// A helper to know if the original, unfiltered list is empty.
  /// This is used to differentiate between "no items" and "no search results".
  bool get isFoodLibraryEmpty => _foodItems.isEmpty;

  /// Loads all food items from the local database.
  Future<void> loadFoodItems() async {
    await guard(() async {
      _foodItems = await _foodService.getFoodItems();
    });
    await _updatePendingCount();
  }

  /// Adds a new food item and then refreshes the list from the source of truth.
  Future<void> addFoodItem(String name, int calories) async {
    await guard(() async {
      await _foodService.addFoodItem(name, calories);
      // Refresh the list to ensure UI is consistent with the database.
      _foodItems = await _foodService.getFoodItems();
    });
    await _updatePendingCount();
  }

  /// Updates an existing food item and refreshes the list.
  Future<void> updateFoodItem(FoodItem item) async {
    await guard(() async {
      await _foodService.updateFoodItem(item);
      _foodItems = await _foodService.getFoodItems();
    });
    await _updatePendingCount();
  }

  /// Deletes a food item and refreshes the list.
  Future<void> deleteFoodItem(String id) async {
    await guard(() async {
      await _foodService.deleteFoodItem(id);
      _foodItems = await _foodService.getFoodItems();
    });
    await _updatePendingCount();
  }

  /// Updates the search query and notifies listeners to rebuild the UI.
  void search(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// A single, private helper to update the pending sync count in the UI.
  Future<void> _updatePendingCount() async {
    final count = await _foodService.getPendingOutboxCount();
    _syncNotifier.setPending(count);
  }

  List<FoodItem> _recentItems = [];
  List<FoodItem> _libraryItems = [];

  // --- GETTERS (with built-in filtering) ---
  List<FoodItem> get recentItems => _searchQuery.isEmpty
      ? _recentItems
      : _recentItems.where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  List<FoodItem> get libraryItems => _searchQuery.isEmpty
      ? _libraryItems
      : _libraryItems.where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  // --- LOGIC ---

  /// Fetches all food data using the 'guard' method for state management.
  Future<void> loadFoods() async {
    await guard(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      final now = DateTime.now();
      _recentItems = [
        FoodItem(id: 'rec_01', name: 'Chicken Breast', calories: 150, servingSize: '100g', imagePath: 'assets/chicken.png', updatedAt: now),
        FoodItem(id: 'rec_02', name: 'Brown Rice', calories: 200, servingSize: '1 cup', imagePath: 'assets/rice.png', updatedAt: now),
      ];
      _libraryItems = [
        FoodItem(id: 'lib_01', name: 'Whole Wheat Toast', calories: 120, servingSize: '2 slices', imagePath: 'assets/toast.png', updatedAt: now),
        FoodItem(id: 'lib_02', name: 'Eggs', calories: 140, servingSize: '2 large', imagePath: 'assets/eggs.png', updatedAt: now),
        FoodItem(id: 'lib_03', name: 'Oatmeal', calories: 80, servingSize: '1 cup', imagePath: 'assets/oatmeal.png', updatedAt: now),
        FoodItem(id: 'lib_04', name: 'Apple', calories: 70, servingSize: '1 medium', imagePath: 'assets/apple.png', updatedAt: now),
        FoodItem(id: 'lib_05', name: 'Almonds', calories: 180, servingSize: '1/4 cup', imagePath: 'assets/almonds.png', updatedAt: now),
      ];
    });
  }
}