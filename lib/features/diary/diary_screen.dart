import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/sync_service.dart';
import '../food/food_notifier.dart';
import '../food/food_screen.dart';
import 'diary_notifier.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  _DailyScreenState createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final SyncService _syncService = SyncService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    // Load initial data from the local database when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DiaryNotifier>(context, listen: false).loadTodaysEntries();
      Provider.of<FoodNotifier>(context, listen: false).loadFoodItems();
    });

    // Start listening for connection changes to trigger auto-sync
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
          final isConnected = results.any((result) => result != ConnectivityResult.none);

          if (isConnected) {
            print("Regained connection, triggering automatic sync...");
            _handleSync();
          } else {
            print("Lost connection.");
          }
        });
  }

  @override
  void dispose() {
    // Clean up the connectivity listener when the widget is removed
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Handles the synchronization process and provides user feedback.
  Future<void> _handleSync() async {
    // Show a temporary message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Syncing with cloud...')),
    );

    await _syncService.sync();

    // Hide the previous message and show a completion message
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sync complete!')),
    );

    // Refresh the UI with any potential data pulled from the server
    await Provider.of<FoodNotifier>(context, listen: false).loadFoodItems();
    await Provider.of<DiaryNotifier>(context, listen: false).loadTodaysEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Diary"),
        actions: [
          // Manual sync button, can be removed if auto-sync is sufficient
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: _handleSync,
            tooltip: 'Sync with Cloud',
          ),
          // Button to navigate to the food library management screen
          IconButton(
            icon: Icon(Icons.library_books),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => FoodScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Header showing total calories
          Consumer<DiaryNotifier>(
            builder: (context, diary, child) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      "Total: ${diary.totalCalories} kcal",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Logged Meal Items List
          Expanded(
            child: Consumer<DiaryNotifier>(
              builder: (context, diary, child) {
                if (diary.todaysEntries.isEmpty) {
                  return Center(child: Text("No meals logged today."));
                }
                return ListView.builder(
                  itemCount: diary.todaysEntries.length,
                  itemBuilder: (context, index) {
                    final entry = diary.todaysEntries[index];
                    return Dismissible(
                      key: Key(entry.id),
                      onDismissed: (direction) {
                        Provider.of<DiaryNotifier>(context, listen: false)
                            .deleteMealEntry(entry.id);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${entry.foodName} removed")),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        title: Text(entry.foodName),
                        trailing: Text("${entry.calories} kcal"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Add Meal',
      ),
    );
  }

  /// Shows a dialog to select a food item from the library to log as a meal.
  void _showAddMealDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final foodItems =
            Provider.of<FoodNotifier>(context, listen: false).foodItems;
        if (foodItems.isEmpty) {
          return AlertDialog(
            title: Text("No Food in Library"),
            content: Text("Please add items to your food library first."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("OK"))
            ],
          );
        }
        return SimpleDialog(
          title: Text("Add Meal"),
          children: foodItems
              .map((foodItem) => SimpleDialogOption(
            onPressed: () {
              Provider.of<DiaryNotifier>(context, listen: false)
                  .addMealEntry(foodItem);
              Navigator.pop(dialogContext);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(foodItem.name),
                  Text("${foodItem.calories} kcal"),
                ],
              ),
            ),
          ))
              .toList(),
        );
      },
    );
  }
}