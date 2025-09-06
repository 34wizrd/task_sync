import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/food_item_model.dart';
import '../../core/network/sync_notifier.dart';
import 'food_notifier.dart';
import 'food_service.dart';

class FoodScreenWrapper extends StatelessWidget {
  const FoodScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FoodNotifier(
        foodService: FoodService(),
        syncNotifier: context.read<SyncNotifier>(),
      ),
      child: const FoodScreen(),
    );
  }
}

//==============================================================================
//--- 5. MAIN SCREEN WIDGET (Stateless) ---
//==============================================================================
class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF30D575);
    const darkBg = Color(0xFF121212);
    const lightText = Color(0xFF8A8A8E);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: darkBg,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _SearchBar(),
              const SizedBox(height: 20),
              const TabBar(
                isScrollable: false, indicatorColor: primaryGreen, indicatorWeight: 3.0,
                labelColor: primaryGreen, unselectedLabelColor: lightText,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: [Tab(text: 'Breakfast'), Tab(text: 'Lunch'), Tab(text: 'Dinner'), Tab(text: 'Snacks')],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Consumer<FoodNotifier>(
                  builder: (context, notifier, child) {
                    if (notifier.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (notifier.error != null) {
                      return Center(child: Text('Error: ${notifier.error}', style: const TextStyle(color: Colors.red)));
                    }
                    return TabBarView(
                      children: [
                        _FoodList(mealTitle: 'Breakfast'),
                        _FoodList(mealTitle: 'Lunch'),
                        _FoodList(mealTitle: 'Dinner'),
                        _FoodList(mealTitle: 'Snacks'),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//==============================================================================
//--- 6. HELPER WIDGETS ---
//==============================================================================

class _SearchBar extends StatefulWidget {
  @override
  State<_SearchBar> createState() => _SearchBarState();
}
class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) context.read<FoodNotifier>().search(_controller.text);
    });
  }
  @override
  void initState() { super.initState(); _controller.addListener(_onSearchChanged); }
  @override
  void dispose() { _debounce?.cancel(); _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller, style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: 'Search for a food', hintStyle: const TextStyle(color: Color(0xFF8A8A8E)),
      prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8A8E)),
      suffixIcon: const Icon(Icons.qr_code_scanner, color: Color(0xFF8A8A8E)),
      filled: true, fillColor: const Color(0xFF2C2C2E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );
}

class _FoodList extends StatelessWidget {
  final String mealTitle;
  const _FoodList({required this.mealTitle});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<FoodNotifier>();
    final recents = notifier.recentItems;
    final libraryFoods = notifier.libraryItems;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recents.isNotEmpty) ...[
            const _SectionHeader(title: 'Recents'),
            const SizedBox(height: 12),
            ListView.separated(
              itemCount: recents.length, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => _FoodListItem(item: recents[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
            ),
            const SizedBox(height: 24),
          ],
          const _SectionHeader(title: 'All Foods'),
          const SizedBox(height: 12),
          if (libraryFoods.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 32.0), child: Center(child: Text('No food items found.', style: TextStyle(color: const Color(0xFF8A8A8E)))))
          else
            ListView.separated(
              itemCount: libraryFoods.length, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => _FoodListItem(item: libraryFoods[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
            ),
          const SizedBox(height: 24),
          const _AddCustomFoodButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
}

class _FoodListItem extends StatelessWidget {
  final FoodItem item;
  const _FoodListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8),
            child: Image.asset(item.imagePath, width: 50, height: 50, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey.shade800, child: const Icon(Icons.fastfood, color: Colors.white)))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(item.details, style: const TextStyle(color: Color(0xFF8A8A8E), fontSize: 14)),
        ],),),
        const SizedBox(width: 16),
        InkWell(
          onTap: () {}, borderRadius: BorderRadius.circular(20),
          child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFF30D575), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.black, size: 24)),
        ),
      ],),);
  }
}

class _AddCustomFoodButton extends StatelessWidget {
  const _AddCustomFoodButton();
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
      label: const Text('Add Custom Food', style: TextStyle(color: Colors.white, fontSize: 16)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: const Color(0xFF8A8A8E).withOpacity(0.5), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }
}