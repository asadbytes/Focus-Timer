import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:focus_timer/firebase_options.dart';
import 'package:focus_timer/models/session.dart';
import 'package:focus_timer/models/sync_operation.dart';
import 'package:focus_timer/models/task.dart';
import 'package:focus_timer/providers/auth_provider.dart';
import 'package:focus_timer/providers/stats_provider.dart';
import 'package:focus_timer/providers/task_provider.dart';
import 'package:focus_timer/router/app_router.dart';
import 'package:focus_timer/services/firestore_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/timer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(SessionAdapter());
  Hive.registerAdapter(SyncOperationAdapter());

  await Hive.openBox("timerBox");
  await Hive.openBox<Task>("tasksBox");
  await Hive.openBox<Session>("sessionsBox");
  await Hive.openBox("settingsBox");
  await Hive.openBox<SyncOperation>("syncQueue");

  final firestoreService = FirestoreService();
  await firestoreService.init();

  runApp(MyApp(firestoreService: firestoreService));
}

class MyApp extends StatefulWidget {
  final FirestoreService firestoreService;
  const MyApp({super.key, required this.firestoreService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.firestoreService),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => TimerProvider(widget.firestoreService),
        ),
        ChangeNotifierProvider(
          create: (context) => TaskProvider(widget.firestoreService),
        ),
        ChangeNotifierProvider(
          create: (context) => StatsProvider(widget.firestoreService),
        ),
      ],
      child: Builder(
        builder: (context) {
          // ✅ Set callback once using addPostFrameCallback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );

            // ✅ Only set if not already set
            if (authProvider.onLoginSuccess == null) {
              authProvider.onLoginSuccess = () async {
                final statsProvider = Provider.of<StatsProvider>(
                  context,
                  listen: false,
                );
                final taskProvider = Provider.of<TaskProvider>(
                  context,
                  listen: false,
                );
                final timerProvider = Provider.of<TimerProvider>(
                  context,
                  listen: false,
                );

                print('🔄 Fetching user data after login...');

                await widget.firestoreService.fetchAllUserData(
                  onSessionsFetched: (sessions) async {
                    await statsProvider.loadSessionsFromCloud(sessions);
                  },
                  onTasksFetched: (tasks) async {
                    await taskProvider.loadTasksFromCloud(tasks);
                  },
                  onSettingsFetched: (settings) async {
                    await timerProvider.loadSettingsFromCloud(settings);
                  },
                );

                print('✅ User data fetch complete');
              };
            }
          });

          return Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return MaterialApp.router(
                title: 'Focus Timer',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.deepPurple,
                    brightness: Brightness.light,
                  ),
                  useMaterial3: true,
                ),
                darkTheme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.deepPurple,
                    brightness: Brightness.dark,
                  ).copyWith(surface: Colors.black),
                ),
                themeMode: ThemeMode.system,
                routerConfig: AppRouter.createRouter(authProvider),
              );
            },
          );
        },
      ),
    );
  }
}
