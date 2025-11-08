import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_timer/models/session.dart';
import 'package:hive/hive.dart';

class TimerProvider extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isFocusSession = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Box _box = Hive.box("timerBox");

  int _focusDuration = 25;
  int _breakDuration = 5;

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isFocusSession => _isFocusSession;
  int get focusDuration => _focusDuration;
  int get breakDuration => _breakDuration;

  Function()? onTimerComplete;

  double get progress {
    final totalSeconds = _isFocusSession
        ? _focusDuration * 60
        : _breakDuration * 60;
    return 1.0 - (_remainingSeconds / totalSeconds);
  }

  TimerProvider() {
    _focusDuration = _box.get("focusDuration", defaultValue: 25);
    _breakDuration = _box.get("breakDuration", defaultValue: 5);
    _remainingSeconds = _focusDuration * 60;
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void startTimer() {
    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = _isFocusSession
        ? _focusDuration * 60
        : _breakDuration * 60;
    notifyListeners();
  }

  void updateDurations(int focus, int breakTime) {
    _focusDuration = focus;
    _breakDuration = breakTime;
    _box.put("focusDuration", focus);
    _box.put("breakDuration", breakTime);
    resetTimer();
  }

  void _onTimerComplete() {
    HapticFeedback.heavyImpact();
    _audioPlayer.play(AssetSource("sounds/comp_sound.mp3"));
    onTimerComplete?.call();

    _timer?.cancel();
    _isRunning = false;
    _saveSession();

    _isFocusSession = !_isFocusSession;
    _remainingSeconds = _isFocusSession
        ? _focusDuration * 60
        : _breakDuration * 60;
    notifyListeners();
  }

  void toggleSessionType() {
    _isFocusSession = !_isFocusSession;
    _remainingSeconds = _isFocusSession
        ? _focusDuration * 60
        : _breakDuration * 60;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _saveSession() {
    final sessionsBox = Hive.box<Session>("sessionsBox");
    final session = Session(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      compeletedAt: DateTime.now(),
      durationMinutes: _isFocusSession ? focusDuration : breakDuration,
      wasFocusSession: _isFocusSession,
    );
    sessionsBox.add(session);
  }
}
