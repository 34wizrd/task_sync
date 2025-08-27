import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'food_notifier.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  _FoodScreenState createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FoodNotifier>(context, listen: false).loadFoodItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Food Library")),
      body: Consumer<FoodNotifier>(
        builder: (context, notifier, child) {
          if (notifier.foodItems.isEmpty) {
            return Center(child: Text("No food items yet. Add one!"));
          }
          return ListView.builder(
            itemCount: notifier.foodItems.length,
            itemBuilder: (context, index) {
              final item = notifier.foodItems[index];
              return ListTile(
                title: Text(item.name),
                trailing: Text("${item.calories} kcal"),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFoodDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Food Item"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Food Name"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: caloriesController,
                decoration: InputDecoration(labelText: "Calories"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Provider.of<FoodNotifier>(context, listen: false).addFoodItem(
                  nameController.text,
                  int.parse(caloriesController.text),
                );
                Navigator.of(context).pop();
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }
}