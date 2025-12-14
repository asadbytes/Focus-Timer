import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_timer/models/session.dart';
import 'package:focus_timer/services/firestore_service.dart';
import 'package:hive/hive.dart';

class TimerProvider extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isFocusSession = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Box _timerBox = Hive.box("timerBox");
  final Box<Session> _sessionsBox = Hive.box<Session>("sessionsBox");
  final FirestoreService _firestoreService;

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

  TimerProvider(this._firestoreService) {
    _focusDuration = _timerBox.get("focusDuration", defaultValue: 25);
    _breakDuration = _timerBox.get("breakDuration", defaultValue: 5);
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
    _timerBox.put("focusDuration", focus);
    _timerBox.put("breakDuration", breakTime);
    resetTimer();
  }

  // ✅ To:
  Future<void> _onTimerComplete() async {
    HapticFeedback.heavyImpact();
    _audioPlayer.play(AssetSource("sounds/comp_sound.mp3"));
    onTimerComplete?.call();

    _timer?.cancel();
    _isRunning = false;

    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch
          .toString(), // ✅ Changed from microseconds
      compeletedAt: DateTime.now(),
      durationMinutes: _isFocusSession ? focusDuration : breakDuration,
      wasFocusSession: _isFocusSession,
    );

    await _saveSession(session); // ✅ Add await
    await _firestoreService.uploadSession(session); // ✅ Add await
    print(
      '📤 Upload queued. Pending: ${_firestoreService.pendingOperationsCount}',
    ); // ✅ Add debug print

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

  Future<void> _saveSession(Session session) async {
    await _sessionsBox.add(session);
    print('💾 Session saved to Hive: ${session.id}');
  }
}
