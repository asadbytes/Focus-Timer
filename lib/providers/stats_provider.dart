import 'package:flutter/material.dart';
import 'package:focus_timer/models/session.dart';
import 'package:hive/hive.dart';

class StatsProvider extends ChangeNotifier {
  List<Session> get allSessions {
    final box = Hive.box<Session>("sessionsBox");
    return box.values.toList()
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

  int get totalFocusSessions {
    return allSessions.where((s) => s.wasFocusSession).length;
  }

  int get todayFocusSessions => todaySessions.length;

  int get thisWeekFocusSessions => thisWeekSessions.length;

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
  }

  Future<void> deleteAllSessions() async {
    final box = Hive.box<Session>("sessionsBox");
    await box.clear();
    notifyListeners();
  }

  Future<void> deleteOldSessions(int daysOld) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final box = Hive.box<Session>("sessionsBox");

    final keysToDelete = <dynamic>[];
    for (var i = 0; i < box.length; i++) {
      final session = box.getAt(i);
      if (session != null && session.compeletedAt.isBefore(cutoffDate)) {
        keysToDelete.add(session.key);
      }
    }

    for (var key in keysToDelete) {
      await box.delete(key);
    }

    notifyListeners();
  }
}
