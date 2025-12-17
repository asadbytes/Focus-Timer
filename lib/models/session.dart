import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 1)
class Session extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final int compeletedAt;
  @HiveField(2)
  final int durationMinutes;
  @HiveField(3)
  final bool wasFocusSession;

  Session({
    required this.id,
    required this.compeletedAt,
    required this.durationMinutes,
    required this.wasFocusSession,
  });

  // ✅ Helper to convert to DateTime when needed
  DateTime get completedAtDate =>
      DateTime.fromMillisecondsSinceEpoch(compeletedAt);

  // ✅ Factory for creating from DateTime
  factory Session.fromDateTime({
    required String id,
    required DateTime completedAt,
    required int durationMinutes,
    required bool wasFocusSession,
  }) {
    return Session(
      id: id,
      compeletedAt: completedAt.millisecondsSinceEpoch,
      durationMinutes: durationMinutes,
      wasFocusSession: wasFocusSession,
    );
  }

  // ✅ Firestore conversion methods
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'completedAt': compeletedAt,
      'durationMinutes': durationMinutes,
      'wasFocusSession': wasFocusSession,
    };
  }

  factory Session.fromFirestore(Map<String, dynamic> data) {
    return Session(
      id: data['id'] as String,
      compeletedAt: data['completedAt'] as int,
      durationMinutes: data['durationMinutes'] as int,
      wasFocusSession: data['wasFocusSession'] as bool,
    );
  }
}
