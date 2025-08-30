import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/main_layout.dart'; // Using the enhanced MainLayout
import '../../core/models/food_item_model.dart';
import '../../core/models/meal_entry_model.dart';
import '../../core/network/sync_notifier.dart';
import '../food/food_notifier.dart';
import '../food/food_screen.dart';
import 'diary_notifier.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  // A hardcoded goal for the UI. In a real app, this would come from user settings.
  static const double _calorieGoal = 2200;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // We can load in parallel for better performance.
    await Future.wait([
      context.read<DiaryNotifier>().loadTodaysEntries(),
      context.read<FoodNotifier>().loadFoodItems(),
    ]);
  }

  Future<void> _handleSync() async {
    final syncNotifier = context.read<SyncNotifier>();
    final messenger = ScaffoldMessenger.of(context);

    await syncNotifier.sync();

    if (!mounted) return;

    messenger.removeCurrentSnackBar();
    if (syncNotifier.error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${syncNotifier.error}'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sync complete!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    }
  }

  void _showAddMealDialog() {
    final foodItems = context.read<FoodNotifier>().foodItems;
    if (foodItems.isEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("No Food in Library"),
          content: const Text("Please add items to your food library first."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => _AddMealDialog(foodItems: foodItems),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // The entire screen is now built on top of MainLayout.
    return MainLayout(
      title: "Today's Diary",
      fab: FloatingActionButton(
        onPressed: _showAddMealDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Meal',
      ),
      // The body is delegated to a separate widget.
      child: _DailyScreenBody(
        onRefresh: _loadData,
        onSync: _handleSync,
        calorieGoal: _calorieGoal,
      ),
    );
  }
}

/// The main content body for the DailyScreen.
class _DailyScreenBody extends StatelessWidget {
  const _DailyScreenBody({
    required this.onRefresh,
    required this.onSync,
    required this.calorieGoal,
  });

  final Future<void> Function() onRefresh;
  final Future<void> Function() onSync;
  final double calorieGoal;

  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryNotifier>();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220.0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: _CalorieSummaryHeader(
                totalCalories: diary.totalCalories,
                goal: calorieGoal,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: onSync,
                tooltip: 'Sync with Cloud',
              ),
              IconButton(
                icon: const Icon(Icons.library_books_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FoodScreen()),
                ),
                tooltip: 'Food Library',
              ),
            ],
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text("Today's Meals",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          _DiaryEntryList(entries: diary.todaysEntries),
        ],
      ),
    );
  }
}

/// A beautiful header that visualizes the daily calorie intake.
class _CalorieSummaryHeader extends StatelessWidget {
  const _CalorieSummaryHeader({required this.totalCalories, required this.goal});

  final int totalCalories;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (goal == 0) ? 0.0 : (totalCalories / goal).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.primaryContainer.withOpacity(0.5),
      margin: const EdgeInsets.all(16),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$totalCalories',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'kcal / ${goal.toInt()}',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays the list of meals or an empty state message.
class _DiaryEntryList extends StatelessWidget {
  const _DiaryEntryList({required this.entries});
  final List<MealEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyDiaryState());
    }

    return SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return _MealListItem(entry: entries[index]);
      },
    );
  }
}

/// A card-based list item for a single meal entry.
class _MealListItem extends StatelessWidget {
  const _MealListItem({required this.entry});
  final MealEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Dismissible(
          key: Key(entry.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            context.read<DiaryNotifier>().deleteMealEntry(entry.id);
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text("${entry.foodName} removed")),
              );
          },
          background: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              child: Icon(Icons.restaurant_menu),
            ),
            title: Text(entry.foodName, style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              "${entry.calories} kcal",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A more engaging empty state for the diary.
class _EmptyDiaryState extends StatelessWidget {
  const _EmptyDiaryState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Your diary is empty',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to log your first meal of the day.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A self-contained dialog for selecting a meal to add.
class _AddMealDialog extends StatelessWidget {
  const _AddMealDialog({required this.foodItems});
  final List<FoodItem> foodItems;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("Select a Meal"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      children: foodItems.map((foodItem) {
        return SimpleDialogOption(
          onPressed: () {
            context.read<DiaryNotifier>().addMealEntry(foodItem);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.fastfood_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(child: Text(foodItem.name)),
                Text("${foodItem.calories} kcal", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}