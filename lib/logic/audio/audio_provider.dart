import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// UI ses efektleri
enum UiSound {
  click1('click1.mp3'),
  click2('click2.mp3'),
  rollover('rollover2.mp3'),
  switch1('switch10.mp3');

  final String fileName;
  const UiSound(this.fileName);

  String get path => 'sfx/UI/$fileName';
}

/// Ses ayarları state sınıfı
class AudioSettings {
  final bool soundEnabled;
  final double volume;

  const AudioSettings({
    this.soundEnabled = true,
    this.volume = 0.7,
  });

  AudioSettings copyWith({
    bool? soundEnabled,
    double? volume,
  }) {
    return AudioSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      volume: volume ?? this.volume,
    );
  }
}

/// UI sesleri için Notifier
class AudioNotifier extends Notifier<AudioSettings> {
  final AudioPlayer _player = AudioPlayer();
  late Box _box;

  @override
  AudioSettings build() {
    // Hive'dan ayarları yükle
    try {
      _box = Hive.box('game_data');
      final soundEnabled = _box.get('ui_sound_enabled', defaultValue: true);
      final volume = _box.get('ui_volume', defaultValue: 0.7);
      return AudioSettings(
        soundEnabled: soundEnabled,
        volume: (volume as num).toDouble(),
      );
    } catch (e) {
      // Hive box açık değilse varsayılan değerlerle devam et
      return const AudioSettings();
    }
  }

  /// Ses açma/kapama
  void setSoundEnabled(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    _saveSettings();
  }

  /// Ses seviyesi ayarlama
  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
    _saveSettings();
  }

  /// Ayarları kaydet
  Future<void> _saveSettings() async {
    try {
      await _box.put('ui_sound_enabled', state.soundEnabled);
      await _box.put('ui_volume', state.volume);
    } catch (e) {
      // Kaydetme hatası - sessizce devam et
    }
  }

  /// Belirli bir ses çal
  Future<void> playSound(UiSound sound) async {
    if (!state.soundEnabled) return;
    
    try {
      await _player.setVolume(state.volume);
      await _player.play(AssetSource(sound.path));
    } catch (e) {
      // Ses çalma hatası - sessizce devam et
    }
  }

  /// Tıklama sesi çal
  Future<void> playClick() async {
    await playSound(UiSound.click1);
  }

  /// Hover sesi çal
  Future<void> playHover() async {
    await playSound(UiSound.rollover);
  }

  /// Switch sesi çal
  Future<void> playSwitch() async {
    await playSound(UiSound.switch1);
  }
}

/// Audio provider
final audioProvider = NotifierProvider<AudioNotifier, AudioSettings>(
  AudioNotifier.new,
);
