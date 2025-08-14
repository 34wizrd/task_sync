import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_sync/src/core/features/todo/todo_provider.dart';
import 'package:task_sync/src/models/todo_model.dart';

class ToDoListScreen extends StatelessWidget {
  const ToDoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My To-Do List')),
      body: Consumer<ToDoProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final todos = [...provider.todos];

          // Sort: incomplete first, then by dueDate (nulls last), then by createdAt
          todos.sort((a, b) {
            if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
            final aHasDue = a.dueDate != null;
            final bHasDue = b.dueDate != null;
            if (aHasDue && bHasDue) {
              final cmp = a.dueDate!.compareTo(b.dueDate!);
              if (cmp != 0) return cmp;
            } else if (aHasDue != bHasDue) {
              return aHasDue ? -1 : 1; // has due date first
            }
            return a.createdAt.compareTo(b.createdAt);
          });

          if (todos.isEmpty) {
            return const Center(child: Text('No to-dos yet! Add one.'));
          }

          return ListView.separated(
            itemCount: todos.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final todo = todos[index];
              final isOverdue = _isOverdue(todo);

              return Dismissible(
                key: ValueKey(todo.id ?? '${todo.title}-$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.red.withValues(alpha: 0.08),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                confirmDismiss: (_) => _confirmDelete(context, todo),
                onDismissed: (_) {
                  final removed = todo;
                  provider.removeTodo(removed); // <-- pass ToDo, not int

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted: ${removed.title}'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          provider.addTodo(removed.title);
                        },
                      ),
                    ),
                  );
                },
                child: CheckboxListTile(
                  value: todo.isCompleted,
                  onChanged: (_) => provider.toggleTodoStatus(todo),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    todo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration:
                      todo.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: _buildSubtitle(todo, isOverdue),
                  secondary: IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final ok = await _confirmDelete(context, todo);
                      if (!context.mounted) return; // avoid using context after await
                      if (ok) {
                        provider.removeTodo(todo); // <-- pass ToDo, not int
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Deleted: ${todo.title}')),
                        );
                      }
                    },
                  ),
                  tileColor: isOverdue && !todo.isCompleted
                      ? Colors.red.withValues(alpha: 0.03)
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add to-do',
        onPressed: () => _showAddTodoDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- Helpers ---

  bool _isOverdue(ToDo t) {
    if (t.dueDate == null || t.isCompleted) return false;
    return t.dueDate!.isBefore(DateTime.now());
  }

  Widget? _buildSubtitle(ToDo todo, bool isOverdue) {
    final parts = <InlineSpan>[];

    if (todo.description != null && todo.description!.trim().isNotEmpty) {
      parts.add(TextSpan(text: todo.description!.trim()));
    }

    if (todo.dueDate != null) {
      if (parts.isNotEmpty) parts.add(const TextSpan(text: ' • '));
      final dueStr = _formatDate(todo.dueDate!);
      parts.add(
        TextSpan(
          text: 'Due $dueStr',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isOverdue ? Colors.red : null,
          ),
        ),
      );
    }

    if (parts.isEmpty) return null;
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black54),
        children: parts,
      ),
    );
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<bool> _confirmDelete(BuildContext context, ToDo todo) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete to-do?'),
        content: Text('“${todo.title}” will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
        false;
    // don't touch `context` after await without checking:
    if (!context.mounted) return false;
    return res;
  }

  void _showAddTodoDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a new to-do'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitNewTodo(ctx, controller.text),
          decoration: const InputDecoration(hintText: 'e.g., Buy groceries'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _submitNewTodo(ctx, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _submitNewTodo(BuildContext dialogContext, String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) {
      Navigator.of(dialogContext).pop();
      return;
    }
    dialogContext.read<ToDoProvider>().addTodo(text);
    Navigator.of(dialogContext).pop();
    if (!dialogContext.mounted) return;
    ScaffoldMessenger.of(dialogContext)
        .showSnackBar(SnackBar(content: Text('Added: $text')));
  }
}
