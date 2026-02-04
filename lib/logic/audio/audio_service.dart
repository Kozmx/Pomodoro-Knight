import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// UI ses efektleri enum'u
enum UiSound {
  click1('click1.mp3'),
  click2('click2.mp3'),
  rollover('rollover2.mp3'),
  switch1('switch10.mp3');

  final String fileName;
  const UiSound(this.fileName);

  String get path => 'sfx/UI/$fileName';
}

/// Ses servisi - UI seslerini yönetir
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _player2 = AudioPlayer(); // Hızlı ardışık sesler için

  bool _soundEnabled = true;
  double _volume = 0.5;
  bool _useSecondPlayer = false;

  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;

  /// Ses ayarlarını yükle
  Future<void> initialize() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player2.setReleaseMode(ReleaseMode.stop);
    // Audio context ayarla
    await _player.setPlayerMode(PlayerMode.lowLatency);
    await _player2.setPlayerMode(PlayerMode.lowLatency);
  }

  /// Sesi aç/kapat
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Ses seviyesini ayarla (0.0 - 1.0)
  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
  }

  /// UI sesi çal
  Future<void> playUiSound(UiSound sound) async {
    if (!_soundEnabled) return;

    try {
      final player = _useSecondPlayer ? _player2 : _player;
      _useSecondPlayer = !_useSecondPlayer;

      await player.setVolume(_volume);
      await player.play(AssetSource(sound.path));
    } catch (e) {
      debugPrint('Ses çalma hatası: $e');
    }
  }

  /// Tıklama sesi çal (varsayılan)
  Future<void> playClick() async {
    await playUiSound(UiSound.click1);
  }

  /// Hover sesi çal
  Future<void> playHover() async {
    await playUiSound(UiSound.rollover);
  }

  /// Switch sesi çal
  Future<void> playSwitch() async {
    await playUiSound(UiSound.switch1);
  }

  void dispose() {
    _player.dispose();
    _player2.dispose();
  }
}
