import 'package:focus_timer/router/app_routes.dart';
import 'package:focus_timer/screens/session_history_screen.dart';
import 'package:focus_timer/screens/settings_screen.dart';
import 'package:focus_timer/screens/stats_screen.dart';
import 'package:focus_timer/screens/tasks_screen.dart';
import 'package:focus_timer/screens/timer_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.timer,
  routes: [
    GoRoute(
      path: AppRoutes.timer,
      name: AppRoutes.timerName,
      builder: (context, state) => const TimerScreen(),
    ),
    GoRoute(
      path: AppRoutes.tasks,
      name: AppRoutes.tasksName,
      builder: (context, state) => const TasksScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: AppRoutes.settingsName,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.stats,
      name: AppRoutes.statsName,
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: AppRoutes.sessionHistory,
      name: AppRoutes.sessionHistoryName,
      builder: (context, state) => const SessionHistoryScreen(),
    ),
  ],
  debugLogDiagnostics: true,
);
