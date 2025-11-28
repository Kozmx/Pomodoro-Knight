import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PomodoroStatus { idle, running, paused }
enum PomodoroMode { work, shortBreak, longBreak }

class PomodoroState {
  final int remainingSeconds;
  final int initialSeconds;
  final PomodoroStatus status;
  final PomodoroMode mode;
  final int workDuration;
  final int shortBreakDuration;
  final int longBreakDuration;

  PomodoroState({
    required this.remainingSeconds,
    required this.initialSeconds,
    this.status = PomodoroStatus.idle,
    this.mode = PomodoroMode.work,
    this.workDuration = 25 * 60,
    this.shortBreakDuration = 5 * 60,
    this.longBreakDuration = 15 * 60,
  });

  PomodoroState copyWith({
    int? remainingSeconds,
    int? initialSeconds,
    PomodoroStatus? status,
    PomodoroMode? mode,
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
  }) {
    return PomodoroState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
    );
  }

  double get progress => initialSeconds == 0 ? 0 : remainingSeconds / initialSeconds;
}

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;

  @override
  PomodoroState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return PomodoroState(
      remainingSeconds: 25 * 60,
      initialSeconds: 25 * 60,
    );
  }

  void startTimer() {
    if (state.status == PomodoroStatus.running) return;

    state = state.copyWith(status: PomodoroStatus.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _timer?.cancel();
        state = state.copyWith(status: PomodoroStatus.idle);
        // Auto-switch mode or notify user could go here
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(status: PomodoroStatus.paused);
  }

  void resetTimer() {
    _timer?.cancel();
    int duration = _getDurationForMode(state.mode);
    state = state.copyWith(
      status: PomodoroStatus.idle,
      remainingSeconds: duration,
      initialSeconds: duration,
    );
  }

  void setWorkDuration(int minutes) {
    final newDuration = minutes * 60;
    state = state.copyWith(workDuration: newDuration);
    if (state.mode == PomodoroMode.work && state.status == PomodoroStatus.idle) {
      state = state.copyWith(
        remainingSeconds: newDuration,
        initialSeconds: newDuration,
      );
    }
  }

  void setShortBreakDuration(int minutes) {
    final newDuration = minutes * 60;
    state = state.copyWith(shortBreakDuration: newDuration);
    if (state.mode == PomodoroMode.shortBreak && state.status == PomodoroStatus.idle) {
      state = state.copyWith(
        remainingSeconds: newDuration,
        initialSeconds: newDuration,
      );
    }
  }

  void setMode(PomodoroMode mode) {
    _timer?.cancel();
    int duration = _getDurationForMode(mode);
    state = state.copyWith(
      mode: mode,
      status: PomodoroStatus.idle,
      remainingSeconds: duration,
      initialSeconds: duration,
    );
  }

  int _getDurationForMode(PomodoroMode mode) {
    switch (mode) {
      case PomodoroMode.work:
        return state.workDuration;
      case PomodoroMode.shortBreak:
        return state.shortBreakDuration;
      case PomodoroMode.longBreak:
        return state.longBreakDuration;
    }
  }

  // No dispose method in Notifier, use ref.onDispose if needed, but Timer needs to be cancelled.
  // We can use ref.onDispose to cancel the timer.
}

final pomodoroProvider = NotifierProvider<PomodoroNotifier, PomodoroState>(PomodoroNotifier.new);
