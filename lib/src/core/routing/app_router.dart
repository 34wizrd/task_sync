import 'package:go_router/go_router.dart';
import '../features/todo/todo_list_screen.dart';

/// The router configuration.
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      name: 'home', // A name to reference this route
      path: '/',
      builder: (context, state) => const ToDoListScreen(),
    ),
    // We can add more routes here later, e.g., for an "add to-do" screen
    // GoRoute(
    //   name: 'add-todo',
    //   path: '/add',
    //   builder: (context, state) => const AddToDoScreen(),
    // ),
  ],
);