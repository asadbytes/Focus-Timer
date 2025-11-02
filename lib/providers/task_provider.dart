import 'package:flutter/material.dart';
import 'package:focus_timer/models/task.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaskProvider extends ChangeNotifier {
  final Box<Task> _box = Hive.box<Task>("tasksBox");

  List<Task> get tasks => _box.values.toList();
  List<Task> get activeTasks => tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => tasks.where((t) => t.isCompleted).toList();

  void addTask(String title) {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now(),
    );

    _box.put(task.id, task);
    notifyListeners();
  }

  void toggleTask(String id) {
    final task = _box.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      _box.put(id, task);
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _box.delete(id);
    notifyListeners();
  }
}
