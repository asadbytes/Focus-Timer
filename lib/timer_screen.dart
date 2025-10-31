import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_timer/settings_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isFocusSession = true;
  int _completedSessions = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _focusDuration = 25;
  int _breakDuration = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Focus Timer"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    focusDuration: _focusDuration,
                    breakDuration: _breakDuration,
                  ),
                ),
              );

              if (result != null) {
                setState(() {
                  _focusDuration = result["focus"];
                  _breakDuration = result["break"];
                  _resetTimer();
                });
              }
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Badge(
                label: Text("$_completedSessions"),
                child: const Icon(Icons.check_circle_outline),
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
                _isFocusSession ? Icons.psychology : Icons.coffee,
              ),
              label: Text(
                _isFocusSession ? "Focus Session" : "Break Time",
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
                      value: _progress,
                      strokeWidth: 12,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: _isFocusSession
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
                  _formatTime(_remainingSeconds),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRunning ? "In Progress" : "Paused",
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
                  onPressed: _resetTimer,
                  child: const Icon(Icons.refresh),
                ),

                const SizedBox(width: 16),

                FilledButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? "Pause" : "Start"),
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

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
      _timer?.cancel();
    });
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _remainingSeconds = _isFocusSession
          ? _focusDuration * 60
          : _breakDuration * 60;
    });
    _timer?.cancel();
  }

  void _onTimerComplete() {
    _timer?.cancel();

    setState(() {
      _isRunning = false;

      if (_isFocusSession) {
        _completedSessions++;
      }

      _isFocusSession = !_isFocusSession;
      _remainingSeconds = _isFocusSession
          ? _focusDuration * 60
          : _breakDuration * 60;
    });

    HapticFeedback.heavyImpact();
    _audioPlayer.play(AssetSource("sounds/comp_sound.mp3"));

    _showCompletionDialog();
  }

  void _toggleSessionType() {
    if (_isRunning) {
      _pauseTimer();
    }

    setState(() {
      _isFocusSession = !_isFocusSession;
      _remainingSeconds = _isFocusSession
          ? _focusDuration * 60
          : _breakDuration * 60;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isFocusSession ? "🎯 Focus Time!" : "☕ Break Time!"),
        content: Text(
          _isFocusSession
              ? "Great job! Time for a $_focusDuration-minute focus session."
              : "Well done! Take a $_breakDuration-minute break.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            child: const Text("Start"),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  double get _progress {
    final totalSeconds = _isFocusSession
        ? _focusDuration * 60
        : _breakDuration * 60;
    return 1.0 - (_remainingSeconds / totalSeconds);
  }
}
