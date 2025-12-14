import 'package:focus_timer/providers/auth_provider.dart';
import 'package:focus_timer/router/app_routes.dart';
import 'package:focus_timer/screens/login_screen.dart';
import 'package:focus_timer/screens/register_screen.dart';
import 'package:focus_timer/screens/session_history_screen.dart';
import 'package:focus_timer/screens/settings_screen.dart';
import 'package:focus_timer/screens/stats_screen.dart';
import 'package:focus_timer/screens/tasks_screen.dart';
import 'package:focus_timer/screens/timer_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.timer,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoggingIn =
            state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register;

        if (!isAuthenticated && !isLoggingIn) {
          return AppRoutes.login;
        }

        if (isAuthenticated && isLoggingIn) {
          return AppRoutes.timer;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.loginName,
          builder: (context, state) => const LoginScreen(),
        ),

        GoRoute(
          path: AppRoutes.register,
          name: AppRoutes.registerName,
          builder: (context, state) => const RegisterScreen(),
        ),

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
  }
}
