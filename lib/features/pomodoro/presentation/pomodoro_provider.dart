import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/features/upgrades/presentation/upgrades_provider.dart';
import 'package:pomodoro_knight/features/auth/presentation/user_provider.dart';
import 'package:pomodoro_knight/features/auth/presentation/auth_provider.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';

// Pomodoro çalışma ve mola durumları
enum PomodoroStatus { idle, running, paused }

// Pomodoro çalışma ve mola modları
enum PomodoroMode { work, shortBreak, longBreak }

// Pomodoro'nun anlık durumunu temsil eden model
class PomodoroState {
  final int remainingSeconds;
  final int initialSeconds;
  final PomodoroStatus status;
  final PomodoroMode mode;
  final int workDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  // Seans sırasında biriken ancak henüz cüzdana eklenmemiş altın
  final int earnedGold;

  PomodoroState({
    required this.remainingSeconds,
    required this.initialSeconds,
    this.status = PomodoroStatus.idle,
    this.mode = PomodoroMode.work,
    this.workDuration = 25 * 60,
    this.shortBreakDuration = 5 * 60,
    this.longBreakDuration = 15 * 60,
    this.earnedGold = 0,
  });

  PomodoroState copyWith({
    int? remainingSeconds,
    int? initialSeconds,
    PomodoroStatus? status,
    PomodoroMode? mode,
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? earnedGold,
  }) {
    return PomodoroState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      earnedGold: earnedGold ?? this.earnedGold,
    );
  }

  // İlerleme yüzdesini hesaplayan getter
  double get progress =>
      initialSeconds == 0 ? 0 : remainingSeconds / initialSeconds;
}

// Pomodoro mantığını yöneten ana sınıf
class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;

  @override
  PomodoroState build() {
    // Sayfa kapandığında timer'ı durdurur
    ref.onDispose(() => _timer?.cancel());
    return PomodoroState(remainingSeconds: 25 * 60, initialSeconds: 25 * 60);
  }

  // Zamanlayıcıyı başlatır
  void startTimer() {
    if (state.status == PomodoroStatus.running) return;

    state = state.copyWith(status: PomodoroStatus.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        // Her saniye süreyi azaltır
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);

        // Çalışma modunda belirli aralıklarla altın biriktirir
        if (state.mode == PomodoroMode.work) {
          final coinMultiplier = ref.read(upgradesProvider).coinMultiplier;

          // Her 6 saniyede bir altın hesaplar
          if ((state.initialSeconds - state.remainingSeconds) % 6 == 0) {
            final goldToAdd = (1 * coinMultiplier).round();
            state = state.copyWith(earnedGold: state.earnedGold + goldToAdd);
            
            // Altın kazanma sesini çal
            GameAudioService().playCoinCollect();
          }
        }
      } else {
        // Süre bittiğinde durdurur ve kaydeder
        _stopAndSave();
      }
    });
  }

  // Süreyi durdurur ve kazanılan altını Firestore'a aktarır
  void _stopAndSave() async {
    _timer?.cancel();

    // Sadece çalışma modunda ve altın birikmişse Firestore'a yazar
    if (state.mode == PomodoroMode.work && state.earnedGold > 0) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        final repo = ref.read(userRepositoryProvider);
        // Firestore'a batch işlemi ile gönderir
        await repo.completePomodoro(
          user.uid,
          state.earnedGold,
          (state.initialSeconds / 60).round(),
        );
      }
    }

    // Durumu sıfırlar ve süreyi seçili moda göre başa sarar
    final duration = _getDurationForMode(state.mode);
    state = state.copyWith(
      status: PomodoroStatus.idle,
      earnedGold: 0,
      remainingSeconds: duration,
      initialSeconds: duration,
    );
  }

  // Zamanlayıcıyı duraklatır
  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(status: PomodoroStatus.paused);
  }

  // Her şeyi başlangıç değerlerine döndürür
  void resetTimer() {
    _timer?.cancel();
    final duration = _getDurationForMode(state.mode);
    state = state.copyWith(
      status: PomodoroStatus.idle,
      remainingSeconds: duration,
      initialSeconds: duration,
      earnedGold: 0,
    );
  }

  // Mod değiştirme işlemi
  void setMode(PomodoroMode mode) {
    _timer?.cancel();
    final duration = _getDurationForMode(mode);
    state = state.copyWith(
      mode: mode,
      status: PomodoroStatus.idle,
      remainingSeconds: duration,
      initialSeconds: duration,
      earnedGold: 0,
    );
  }

  // Seçili moda göre süreyi döner
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

  // Çalışma süresini günceller
  void setWorkDuration(int minutes) {
    final seconds = minutes * 60;
    state = state.copyWith(workDuration: seconds);
    // Eğer şu an çalışma modundaysak ve timer çalışmıyorsa süreyi hemen güncelle
    if (state.mode == PomodoroMode.work &&
        state.status == PomodoroStatus.idle) {
      state = state.copyWith(
        remainingSeconds: seconds,
        initialSeconds: seconds,
      );
    }
  }

  // Kısa mola süresini günceller
  void setShortBreakDuration(int minutes) {
    final seconds = minutes * 60;
    state = state.copyWith(shortBreakDuration: seconds);
    // Eğer şu an kısa mola modundaysak ve timer çalışmıyorsa süreyi hemen güncelle
    if (state.mode == PomodoroMode.shortBreak &&
        state.status == PomodoroStatus.idle) {
      state = state.copyWith(
        remainingSeconds: seconds,
        initialSeconds: seconds,
      );
    }
  }
}

// Global erişim için provider tanımı
final pomodoroProvider = NotifierProvider<PomodoroNotifier, PomodoroState>(
  PomodoroNotifier.new,
);
