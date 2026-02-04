import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'audio_service.dart';

/// Ses ayarları state'i
class AudioSettings {
  final bool soundEnabled;
  final double volume;

  const AudioSettings({this.soundEnabled = true, this.volume = 0.5});

  AudioSettings copyWith({bool? soundEnabled, double? volume}) {
    return AudioSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      volume: volume ?? this.volume,
    );
  }
}

/// Ses ayarları notifier'ı
class AudioNotifier extends Notifier<AudioSettings> {
  late Box _box;

  @override
  AudioSettings build() {
    _box = Hive.box('game_data');
    final soundEnabled = _box.get('sound_enabled', defaultValue: true) as bool;
    final volume = _box.get('sound_volume', defaultValue: 0.5) as double;

    final audioService = ref.watch(audioServiceProvider);
    audioService.setSoundEnabled(soundEnabled);
    audioService.setVolume(volume);

    return AudioSettings(soundEnabled: soundEnabled, volume: volume);
  }

  Future<void> _saveSettings() async {
    await _box.put('sound_enabled', state.soundEnabled);
    await _box.put('sound_volume', state.volume);
  }

  /// Sesi aç/kapat
  void toggleSound() {
    final newEnabled = !state.soundEnabled;
    state = state.copyWith(soundEnabled: newEnabled);
    ref.read(audioServiceProvider).setSoundEnabled(newEnabled);
    _saveSettings();
  }

  /// Sesi aktif/pasif yap
  void setSoundEnabled(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    ref.read(audioServiceProvider).setSoundEnabled(enabled);
    _saveSettings();
  }

  /// Ses seviyesini ayarla
  void setVolume(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    state = state.copyWith(volume: clampedVolume);
    ref.read(audioServiceProvider).setVolume(clampedVolume);
    _saveSettings();
  }

  /// Tıklama sesi çal
  Future<void> playClick() async {
    await ref.read(audioServiceProvider).playClick();
  }

  /// Hover sesi çal
  Future<void> playHover() async {
    await ref.read(audioServiceProvider).playHover();
  }

  /// Switch sesi çal
  Future<void> playSwitch() async {
    await ref.read(audioServiceProvider).playSwitch();
  }

  /// Belirli bir UI sesi çal
  Future<void> playSound(UiSound sound) async {
    await ref.read(audioServiceProvider).playUiSound(sound);
  }
}

/// Audio service provider
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Audio settings provider
final audioProvider = NotifierProvider<AudioNotifier, AudioSettings>(() {
  return AudioNotifier();
});
