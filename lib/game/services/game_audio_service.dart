import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Oyun ses efektleri - footstep, kılıç vb.
enum GameSound {
  // Footstep varyasyonları
  footstep02('footstep02.mp3'),
  footstep03('footstep03.mp3'),
  footstep04('footstep04.mp3'),
  footstep05('footstep05.mp3'),
  footstep06('footstep06.mp3'),
  footstep07('footstep07.mp3'),

  // Kılıç sesleri
  swordSwoosh('sword_swoosh.mp3'),
  swordStab('sword_stab.mp3'),
  swordStab2('sword stap2.mp3'),

  // XP toplama sesi (coin benzeri)
  xpCollect('xp_collect.mp3');

  final String fileName;
  const GameSound(this.fileName);

  String get path => 'sfx/game sfx/$fileName';
}

/// Oyun ses servisi - footstep, kılıç gibi oyun içi sesler
class GameAudioService {
  static final GameAudioService _instance = GameAudioService._internal();
  factory GameAudioService() => _instance;
  GameAudioService._internal();

  // Birden fazla player - overlapping sesler için
  final List<AudioPlayer> _players = [];
  int _currentPlayerIndex = 0;
  static const int _maxPlayers = 4;

  final Random _random = Random();

  bool _soundEnabled = true;
  double _volume = 0.6;
  double _sfxVolume = 0.8; // SFX için ayrı ses seviyesi

  // Footstep için cooldown
  double _footstepCooldown = 0;
  static const double _footstepInterval = 0.25; // saniye

  // Footstep varyasyonları
  static const List<GameSound> _footstepSounds = [
    GameSound.footstep02,
    GameSound.footstep03,
    GameSound.footstep04,
    GameSound.footstep05,
    GameSound.footstep06,
    GameSound.footstep07,
  ];

  // Kılıç swoosh varyasyonları için pitch değişimi
  int _lastFootstepIndex = -1;

  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;

  /// Ses servisini başlat
  Future<void> initialize() async {
    for (int i = 0; i < _maxPlayers; i++) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setPlayerMode(PlayerMode.lowLatency);
      _players.add(player);
    }
  }

  /// Sesi aç/kapat
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Genel ses seviyesini ayarla
  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
  }

  /// SFX ses seviyesini ayarla
  void setSfxVolume(double vol) {
    _sfxVolume = vol.clamp(0.0, 1.0);
  }

  /// Sonraki player'ı al (round-robin)
  AudioPlayer _getNextPlayer() {
    final player = _players[_currentPlayerIndex];
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _maxPlayers;
    return player;
  }

  /// Oyun sesi çal
  Future<void> playSound(GameSound sound, {double? volumeMultiplier}) async {
    if (!_soundEnabled || _players.isEmpty) return;

    try {
      final player = _getNextPlayer();
      final finalVolume = _volume * _sfxVolume * (volumeMultiplier ?? 1.0);

      await player.setVolume(finalVolume.clamp(0.0, 1.0));
      await player.play(AssetSource(sound.path));
    } catch (e) {
      debugPrint('Oyun sesi çalma hatası: $e');
    }
  }

  /// Pitch randomizer ile ses çal (daha doğal ses için)
  Future<void> playSoundWithPitchVariation(
    GameSound sound, {
    double minPitch = 0.9,
    double maxPitch = 1.1,
    double? volumeMultiplier,
  }) async {
    if (!_soundEnabled || _players.isEmpty) return;

    try {
      final player = _getNextPlayer();
      final finalVolume = _volume * _sfxVolume * (volumeMultiplier ?? 1.0);

      // Pitch rastgele ayarla
      final pitch = minPitch + _random.nextDouble() * (maxPitch - minPitch);

      await player.setVolume(finalVolume.clamp(0.0, 1.0));
      await player.setPlaybackRate(pitch);
      await player.play(AssetSource(sound.path));

      // Pitch'i normale döndür (sonraki sesler için)
      // Not: Bu async olduğu için ses çalmaya başladıktan sonra sıfırlanacak
      Future.delayed(const Duration(milliseconds: 500), () {
        player.setPlaybackRate(1.0);
      });
    } catch (e) {
      debugPrint('Oyun sesi çalma hatası (pitch): $e');
    }
  }

  /// Footstep sesi çal - varyasyonlu ve cooldown'lu
  void playFootstep(double dt) {
    _footstepCooldown -= dt;

    if (_footstepCooldown <= 0) {
      // Rastgele footstep seç (son çalandan farklı)
      int newIndex;
      do {
        newIndex = _random.nextInt(_footstepSounds.length);
      } while (newIndex == _lastFootstepIndex && _footstepSounds.length > 1);

      _lastFootstepIndex = newIndex;

      // Pitch varyasyonu ile çal
      playSoundWithPitchVariation(
        _footstepSounds[newIndex],
        minPitch: 0.85,
        maxPitch: 1.15,
        volumeMultiplier: 0.7,
      );

      _footstepCooldown = _footstepInterval;
    }
  }

  /// Footstep cooldown'ı sıfırla (durduğunda)
  void resetFootstepCooldown() {
    _footstepCooldown = 0;
  }

  /// Kılıç swoosh sesi çal
  Future<void> playSwordSwoosh() async {
    await playSoundWithPitchVariation(
      GameSound.swordSwoosh,
      minPitch: 0.9,
      maxPitch: 1.1,
      volumeMultiplier: 0.9,
    );
  }

  /// Kılıç vuruş sesi çal (düşmana değdiğinde)
  Future<void> playSwordHit() async {
    // İki stab sesinden rastgele birini seç
    final sound = _random.nextBool()
        ? GameSound.swordStab
        : GameSound.swordStab2;

    await playSoundWithPitchVariation(
      sound,
      minPitch: 0.85,
      maxPitch: 1.15,
      volumeMultiplier: 1.0,
    );
  }

  /// XP toplama sesi çal (coin benzeri efekt)
  Future<void> playXpCollect() async {
    // Not: xp_collect.mp3 dosyası yoksa footstep02'yi yüksek pitch ile çal
    // Gerçek coin sesi eklendiğinde bu satırı değiştir
    try {
      await playSoundWithPitchVariation(
        GameSound.xpCollect,
        minPitch: 1.2,
        maxPitch: 1.6,
        volumeMultiplier: 0.5,
      );
    } catch (e) {
      // Fallback: footstep sesi yüksek pitch ile
      await playSoundWithPitchVariation(
        GameSound.footstep02,
        minPitch: 1.5,
        maxPitch: 2.0,
        volumeMultiplier: 0.4,
      );
    }
  }

  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
    _players.clear();
  }
}
