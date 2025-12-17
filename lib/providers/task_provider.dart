import 'package:flutter/material.dart';
import 'package:focus_timer/models/task.dart';
import 'package:focus_timer/services/firestore_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaskProvider extends ChangeNotifier {
  final Box<Task> _taskBox = Hive.box<Task>("tasksBox");
  final FirestoreService _firestoreService;

  TaskProvider(this._firestoreService);

  List<Task> get tasks => _taskBox.values.toList();
  List<Task> get activeTasks => tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => tasks.where((t) => t.isCompleted).toList();

  void addTask(String title) {
    final task = Task.fromDateTime(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now(),
    );

    _taskBox.put(task.id, task);
    notifyListeners();
    _firestoreService.uploadTask(task);
  }

  void toggleTask(String id) {
    final task = _taskBox.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      _taskBox.put(id, task);
      notifyListeners();
      _firestoreService.updateTask(task);
    }
  }

  void deleteTask(String id) {
    _taskBox.delete(id);
    notifyListeners();
    _firestoreService.deleteTask(id);
  }

  Future<void> loadTasksFromCloud(List<Task> cloudTasks) async {
    for (final task in cloudTasks) {
      await _taskBox.put(task.id, task);
    }
    notifyListeners();
    print('✅ Loaded ${cloudTasks.length} tasks from cloud');
  }
}
