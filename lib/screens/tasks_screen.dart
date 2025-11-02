import 'package:flutter/material.dart';
import 'package:focus_timer/providers/task_provider.dart';
import 'package:provider/provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Tasks"), centerTitle: true),
      body: taskProvider.tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: colorScheme.outline),

                  SizedBox(height: 16),

                  Text(
                    "No tasks yet",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                if (taskProvider.tasks.isNotEmpty) ...[
                  Text(
                    "Active Tasks",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...taskProvider.activeTasks.map(
                    (task) => Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (context) =>
                              taskProvider.toggleTask(task.id),
                        ),
                        title: Text(task.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => taskProvider.deleteTask(task.id),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (taskProvider.completedTasks.isNotEmpty) ...[
                  Text(
                    "Completed Tasks",
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  ...taskProvider.completedTasks.map(
                    (task) => Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (context) =>
                              taskProvider.toggleTask(task.id),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => taskProvider.deleteTask(task.id),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context, taskProvider),
        icon: const Icon(Icons.add),
        label: const Text("Add Task"),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Task"),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: "Enter task name",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              taskProvider.addTask(value.trim());
              _controller.clear();
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _controller.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                taskProvider.addTask(_controller.text.trim());
                _controller.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
