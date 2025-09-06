import 'package:flutter/material.dart';

// --- DATA MODELS (Used to structure the UI's hardcoded data) ---

/// Represents a single food entry in the daily log.
class FoodLog {
  final IconData icon;
  final String name;
  final String meal;
  final int calories;

  const FoodLog({
    required this.icon,
    required this.name,
    required this.meal,
    required this.calories,
  });
}

/// Represents the progress for a single macronutrient.
class MacroData {
  final String name;
  final int current;
  final int total;
  final Color color;

  const MacroData({
    required this.name,
    required this.current,
    required this.total,
    required this.color,
  });
}

// --- FINAL DASHBOARD SCREEN WIDGET ---

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // --- Hardcoded data for UI demonstration ---
  // In a real app, this data would come from a notifier (e.g., DiaryNotifier).
  final int consumed = 1850;
  final int goal = 2500;
  final int remaining = 650;

  final List<FoodLog> foodLogs = const [
    FoodLog(icon: Icons.lunch_dining, name: 'Grilled Chicken Salad', meal: 'Lunch', calories: 450),
    FoodLog(icon: Icons.egg, name: 'Scrambled Eggs', meal: 'Breakfast', calories: 300),
    FoodLog(icon: Icons.local_drink, name: 'Protein Shake', meal: 'Snack', calories: 250),
    FoodLog(icon: Icons.restaurant, name: 'Salmon with Quinoa', meal: 'Dinner', calories: 850),
  ];

  final List<MacroData> macros = const [
    MacroData(name: 'Carbs', current: 135, total: 313, color: Color(0xFF30D575)),
    MacroData(name: 'Protein', current: 90, total: 188, color: Color(0xFF30D575)),
  ];

  @override
  Widget build(BuildContext context) {
    // --- Color palette derived from the design ---
    const primaryGreen = Color(0xFF30D575);
    const darkBg = Color(0xFF121212);
    const cardBg = Color(0xFF1C1C1E);
    const lightText = Color(0xFF8A8A8E);

    // This screen's root is a Container, making it embeddable.
    // It does not include Scaffold, AppBar, or BottomNavigationBar.
    return Container(
      color: darkBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Calorie Summary Cards Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CalorieInfoCard(title: 'Consumed', value: consumed, color: primaryGreen),
                _CalorieInfoCard(title: 'Goal', value: goal),
                _CalorieInfoCard(title: 'Remaining', value: remaining, color: primaryGreen),
              ],
            ),
            const SizedBox(height: 24),

            // --- Total Calories Progress Bar Section ---
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (consumed / goal).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: cardBg,
                valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
            ),
            const SizedBox(height: 32),

            // --- "Today's Log" Section ---
            const Text(
              "Today's Log",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              itemCount: foodLogs.length,
              shrinkWrap: true, // Necessary for lists inside a scroll view
              physics: const NeverScrollableScrollPhysics(), // Disables list's own scrolling
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _FoodLogItem(log: foodLogs[index], cardBg: cardBg, lightText: lightText);
              },
            ),
            const SizedBox(height: 32),

            // --- "Macronutrients Progress" Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Macronutrients Progress',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              itemCount: macros.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                return _MacroProgressIndicator(data: macros[index], cardBg: cardBg);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- REUSABLE SUB-WIDGETS for the Dashboard Screen ---

/// A card displaying a single calorie metric (e.g., Consumed, Goal).
class _CalorieInfoCard extends StatelessWidget {
  final String title;
  final int value;
  final Color? color;

  const _CalorieInfoCard({required this.title, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF8A8A8E), fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(color: color ?? Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('kcal', style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// A list item representing a single logged food item.
class _FoodLogItem extends StatelessWidget {
  final FoodLog log;
  final Color cardBg;
  final Color lightText;

  const _FoodLogItem({required this.log, required this.cardBg, required this.lightText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(log.icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${log.meal} - ${log.calories} kcal', style: TextStyle(color: lightText, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

/// A widget that shows a label and a progress bar for a single macronutrient.
class _MacroProgressIndicator extends StatelessWidget {
  final MacroData data;
  final Color cardBg;

  const _MacroProgressIndicator({required this.data, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(data.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text('${data.current}g / ${data.total}g', style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (data.current / data.total).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: cardBg,
            valueColor: AlwaysStoppedAnimation<Color>(data.color),
          ),
        ),
      ],
    );
  }
}