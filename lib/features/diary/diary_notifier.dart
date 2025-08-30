import '../../core/base/base_notifier.dart';
import '../../core/models/food_item_model.dart';
import '../../core/models/meal_entry_model.dart';
import '../../core/network/sync_notifier.dart';
import '../food/food_service.dart';
import 'diary_service.dart';

/// Manages the state for the daily diary screen.
class DiaryNotifier extends BaseNotifier {
  DiaryNotifier({
    required DiaryService diaryService,
    required SyncNotifier syncNotifier,
  })  : _diaryService = diaryService,
        _syncNotifier = syncNotifier;

  final DiaryService _diaryService;
  final SyncNotifier _syncNotifier;

  List<MealEntry> _todaysEntries = [];
  List<MealEntry> get todaysEntries => _todaysEntries;

  /// A computed property to get the total calories for the day.
  int get totalCalories {
    return _todaysEntries.fold(0, (sum, entry) => sum + entry.calories);
  }

  /// Loads all of today's meal entries from the local database.
  Future<void> loadTodaysEntries() async {
    await guard(() async {
      _todaysEntries = await _diaryService.getTodaysEntries();
    });
    // No need to update pending count here, as loading doesn't create new pending items.
  }

  /// Adds a new meal entry based on a selected food item.
  Future<void> addMealEntry(FoodItem foodItem) async {
    await guard(() async {
      await _diaryService.addMealEntry(foodItem);
      // Refresh the list from the source of truth to show the new entry.
      _todaysEntries = await _diaryService.getTodaysEntries();
    });
    await _updatePendingCount();
  }

  /// Deletes a meal entry.
  Future<void> deleteMealEntry(String id) async {
    await guard(() async {
      await _diaryService.deleteMealEntry(id);
      _todaysEntries.removeWhere((entry) => entry.id == id);
    });
    await _updatePendingCount();
  }

  /// A helper to update the pending sync count in the UI.
  Future<void> _updatePendingCount() async {
    // In a larger app, you might get this from a shared service.
    // For now, we assume FoodService can count the whole outbox.
    final foodService = FoodService(); // A bit of a shortcut here
    final count = await foodService.getPendingOutboxCount();
    _syncNotifier.setPending(count);
  }
}