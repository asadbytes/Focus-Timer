import 'package:flutter/material.dart';
import 'package:focus_timer/providers/stats_provider.dart';
import 'package:focus_timer/providers/timer_provider.dart';
import 'package:focus_timer/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timerProvider = Provider.of<TimerProvider>(context);
    final statsProvider = Provider.of<StatsProvider>(context);
    timerProvider.onTimerComplete = _showCompletionDialog;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Focus Timer"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.push(AppRoutes.tasks),
            tooltip: "Tasks",
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push(AppRoutes.stats),
            tooltip: "Statistics",
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: "Settings",
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => _showCounterModeDialog(context, statsProvider),
                child: Badge(
                  label: Text("${statsProvider.displayCount}"),
                  child: const Icon(Icons.check_circle_outline),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(
              avatar: Icon(
                size: 25,
                timerProvider.isFocusSession ? Icons.psychology : Icons.coffee,
              ),
              label: Text(
                timerProvider.isFocusSession ? "Focus Session" : "Break Time",
                style: theme.textTheme.titleMedium,
              ),
              backgroundColor: colorScheme.secondaryContainer,
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CircularProgressIndicator(
                      value: timerProvider.progress,
                      strokeWidth: 12,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: timerProvider.isFocusSession
                          ? colorScheme.primary
                          : colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timerProvider.formatTime(timerProvider.remainingSeconds),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timerProvider.isRunning ? "In Progress" : "Paused",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 64),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: timerProvider.resetTimer,
                  child: const Icon(Icons.refresh),
                ),

                const SizedBox(width: 16),

                FilledButton.icon(
                  onPressed: timerProvider.isRunning
                      ? timerProvider.pauseTimer
                      : timerProvider.startTimer,
                  icon: Icon(
                    timerProvider.isRunning ? Icons.pause : Icons.play_arrow,
                  ),
                  label: Text(timerProvider.isRunning ? "Pause" : "Start"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                FilledButton.tonal(
                  onPressed: _toggleSessionType,
                  child: const Icon(Icons.swap_horiz),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCounterModeDialog(
    BuildContext context,
    StatsProvider statsProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Counter Display"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<CounterMode>(
              groupValue: statsProvider.counterMode,
              onChanged: (mode) {
                if (mode != null) {
                  statsProvider.setCounterMode(mode);
                  Navigator.pop(context);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    title: const Text("All Time"),
                    value: CounterMode.allTime,
                  ),
                  RadioListTile(
                    title: const Text("Today"),
                    value: CounterMode.daily,
                  ),
                  RadioListTile(
                    title: const Text("This Week"),
                    value: CounterMode.weekly,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSessionType() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    if (timerProvider.isRunning) {
      timerProvider.pauseTimer();
    }

    timerProvider.toggleSessionType();
  }

  void _showCompletionDialog() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          timerProvider.isFocusSession ? "🎯 Focus Time!" : "☕ Break Time!",
        ),
        content: Text(
          timerProvider.isFocusSession
              ? "Great job! Time for a ${timerProvider.focusDuration}-minute focus session."
              : "Well done! Take a ${timerProvider.breakDuration}-minute break.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              timerProvider.startTimer();
            },
            child: const Text("Start"),
          ),
        ],
      ),
    );
  }
}
