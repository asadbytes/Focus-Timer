import 'package:hive/hive.dart';

part 'sync_operation.g.dart';

@HiveType(typeId: 2)
class SyncOperation extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String operationType;
  @HiveField(2)
  final Map<String, dynamic> data;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  int retryCount;

  SyncOperation({
    required this.id,
    required this.operationType,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });
}
