import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  bool isCompleted;
  @HiveField(3)
  final int createdAt;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
  });

  // ✅ Helper to convert to DateTime when needed
  DateTime get createdAtDate => DateTime.fromMillisecondsSinceEpoch(createdAt);

  // ✅ Factory for creating from DateTime
  factory Task.fromDateTime({
    required String id,
    required String title,
    bool isCompleted = false,
    required DateTime createdAt,
  }) {
    return Task(
      id: id,
      title: title,
      isCompleted: isCompleted,
      createdAt: createdAt.millisecondsSinceEpoch,
    );
  }

  // ✅ Firestore conversion methods
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt,
    };
  }

  factory Task.fromFirestore(Map<String, dynamic> data) {
    return Task(
      id: data['id'] as String,
      title: data['title'] as String,
      isCompleted: data['isCompleted'] as bool,
      createdAt: data['createdAt'] as int,
    );
  }
}
