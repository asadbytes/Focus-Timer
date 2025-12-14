import 'package:flutter/material.dart';
import 'package:focus_timer/models/session.dart';
import 'package:focus_timer/services/firestore_service.dart';
import 'package:hive/hive.dart';

enum CounterMode { allTime, daily, weekly }

class StatsProvider extends ChangeNotifier {
  late final Box<Session> _sessionsBox;
  final FirestoreService _firestoreService;
  late final Box _settingsBox;
  CounterMode _counterMode = CounterMode.allTime;

  StatsProvider(this._firestoreService) {
    _sessionsBox = Hive.box<Session>("sessionsBox");
    _settingsBox = Hive.box("settingsBox");
    _loadCounterMode();
  }

  CounterMode get counterMode => _counterMode;
  FirestoreService get firestoreService => _firestoreService;

  List<Session> get allSessions {
    return _sessionsBox.values.toList()
      ..sort((a, b) => b.compeletedAt.compareTo(a.compeletedAt));
  }

  List<Session> get todaySessions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allSessions.where((session) {
      final sessionDate = DateTime(
        session.compeletedAt.year,
        session.compeletedAt.month,
        session.compeletedAt.day,
      );
      return sessionDate == today && session.wasFocusSession;
    }).toList();
  }

  List<Session> get thisWeekSessions {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    return allSessions.where((session) {
      return session.compeletedAt.isAfter(weekStartDate) &&
          session.wasFocusSession;
    }).toList();
  }

  void _loadCounterMode() {
    final saved = _settingsBox.get("counterMode", defaultValue: 0);
    _counterMode = CounterMode.values[saved];
  }

  void setCounterMode(CounterMode mode) {
    _counterMode = mode;
    _settingsBox.put("counterMode", mode.index);
    notifyListeners();
  }

  int get totalFocusSessions {
    return allSessions.where((s) => s.wasFocusSession).length;
  }

  int get todayFocusSessions => todaySessions.length;

  int get thisWeekFocusSessions => thisWeekSessions.length;

  int get displayCount {
    switch (_counterMode) {
      case CounterMode.daily:
        return todayFocusSessions;
      case CounterMode.weekly:
        return thisWeekFocusSessions;
      case CounterMode.allTime:
        return totalFocusSessions;
    }
  }

  Map<DateTime, int> get last7DaysData {
    final now = DateTime.now();
    final Map<DateTime, int> data = {};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      data[dateKey] = 0;
    }

    for (var session in allSessions) {
      if (!session.wasFocusSession) continue;

      final sessionDate = DateTime(
        session.compeletedAt.year,
        session.compeletedAt.month,
        session.compeletedAt.day,
      );

      if (data.containsKey(sessionDate)) {
        data[sessionDate] = data[sessionDate]! + 1;
      }
    }

    return data;
  }

  void deleteSession(Session session) {
    session.delete();
    notifyListeners();
    _firestoreService.deleteSession(session.id);
  }

  Future<void> deleteAllSessions() async {
    final sessionsBox = Hive.box<Session>("sessionsBox");
    await sessionsBox.clear();
    notifyListeners();
    final allIds = allSessions.map((s) => s.id).toList();
    _firestoreService.deleteBulkSessions(allIds);
  }

  Future<void> deleteOldSessions(int daysOld) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final sessionsBox = Hive.box<Session>("sessionsBox");

    final keysToDelete = <dynamic>[];
    final idsToDelete = <String>[];
    for (var i = 0; i < sessionsBox.length; i++) {
      final session = sessionsBox.getAt(i);
      if (session != null && session.compeletedAt.isBefore(cutoffDate)) {
        keysToDelete.add(session.key);
        idsToDelete.add(session.id);
      }
    }

    for (var key in keysToDelete) {
      await sessionsBox.delete(key);
    }
    notifyListeners();
    _firestoreService.deleteBulkSessions(idsToDelete);
  }
}
