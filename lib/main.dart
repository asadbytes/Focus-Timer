import 'package:cloud_firestore/cloud_firestore.dart';
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

class MyApp extends StatelessWidget {
  final FirestoreService firestoreService;
  const MyApp({super.key, required this.firestoreService});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: firestoreService),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => TimerProvider(firestoreService),
        ),
        ChangeNotifierProvider(
          create: (context) => TaskProvider(firestoreService),
        ),
        ChangeNotifierProvider(
          create: (context) => StatsProvider(firestoreService),
        ),
      ],
      child: Consumer<AuthProvider>(
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
      ),
    );
  }
}
