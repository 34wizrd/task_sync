import 'dart:async'; // Imported for search debouncing timer

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../widgets/main_layout.dart'; // Assumes MainLayout is in this path
import 'food_notifier.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodNotifier>().loadFoodItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Food Library',
      fab: FloatingActionButton(
        tooltip: 'Add Food',
        onPressed: () => _showAddFoodSheet(context),
        child: const Icon(Icons.add),
      ),
      child: const _FoodScreenBody(),
    );
  }

  void _showAddFoodSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddFoodSheet(notifier: context.read<FoodNotifier>()),
    );
  }
}

/// The main body of the screen, responsible for displaying content based on notifier state.
class _FoodScreenBody extends StatelessWidget {
  const _FoodScreenBody();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<FoodNotifier>();

    // UPDATE: Handle error states from the BaseNotifier.
    if (notifier.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'An error occurred: ${notifier.error}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => notifier.loadFoodItems(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadFoodItems(),
      child: notifier.isLoading && notifier.isFoodLibraryEmpty
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _SearchField()),
          if (notifier.isFoodLibraryEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: _EmptyState(),
              ),
            )
          else if (notifier.foodItems.isEmpty && !notifier.isFoodLibraryEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Center(
                  child: Text(
                    "No food found for your search.",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            const _FoodList(),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

/// A dedicated widget for the search input field with debouncing.
class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  // UPDATE: Debounce the search input to improve performance.
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<FoodNotifier>().search(query);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        decoration: const InputDecoration(
          hintText: 'Search food...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          isDense: true,
        ),
      ),
    );
  }
}

/// A widget that displays the filtered list of food items with swipe-to-delete.
class _FoodList extends StatelessWidget {
  const _FoodList();

  @override
  Widget build(BuildContext context) {
    final items = context.watch<FoodNotifier>().foodItems;
    final notifier = context.read<FoodNotifier>();

    return SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = items[i];

        // UPDATE: Wrap ListTile in Dismissible for swipe-to-delete functionality.
        return Dismissible(
          key: Key(item.id), // A unique key is required.
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            notifier.deleteFoodItem(item.id);
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('Deleted ${item.name}')),
              );
          },
          background: Container(
            color: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              'ID: ${item.id}',
              style: TextStyle(color: Colors.black.withOpacity(0.55)),
            ),
            trailing: _KcalChip(kcal: item.calories),
          ),
        );
      },
    );
  }
}

/// A self-contained widget for the "Add Food" form.
class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet({required this.notifier});
  final FoodNotifier notifier;

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  // BUG FIX: Corrected typo from "TextEditing TextEditingController"
  final _calCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    final cal = int.parse(_calCtrl.text.trim());

    await widget.notifier.addFoodItem(name, cal);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Added $name')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Text('Add Food Item', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Food name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _calCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Calories',
                helperText: 'kcal per item/serving',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// These widgets required no changes.
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant, size: 56, color: Colors.black.withOpacity(0.35)),
          const SizedBox(height: 12),
          Text('No food items yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Tap the + button to add your first item.', style: TextStyle(color: Colors.black.withOpacity(0.65)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _KcalChip extends StatelessWidget {
  const _KcalChip({required this.kcal});
  final int kcal;
  @override
  Widget build(BuildContext context) {
    final bg = Colors.orange.withOpacity(0.12);
    final fg = Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, border: Border.all(color: fg.withOpacity(0.35)), borderRadius: BorderRadius.circular(999)),
      child: Text('$kcal kcal', style: TextStyle(color: fg, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
    );
  }
}