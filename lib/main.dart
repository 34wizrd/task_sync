import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_sync/src/core/features/todo/todo_provider.dart';
import 'package:task_sync/src/core/routing/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider makes the ToDoProvider available to all widgets
    // below it in the widget tree.
    return ChangeNotifierProvider(
      create: (context) => ToDoProvider(),
      child: MaterialApp.router(
        title: 'Offline-First To-Do App',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          useMaterial3: true,
        ),
        // Tell the MaterialApp to use our GoRouter configuration.
        routerConfig: router,
      ),
    );
  }
}