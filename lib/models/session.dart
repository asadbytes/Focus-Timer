import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 1)
class Session extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime compeletedAt;
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
}
