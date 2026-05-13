import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  swordSwing('389590__jofae__swing-woosh.wav'),
  swordStab('sword_stab.mp3'),
  swordStab2('sword stap2.mp3'),

  // Oyuncu sesleri
  playerHurt('hurt.wav'),
  playerHurt2('hurt 2.wav'),
  playerDeath('death.wav'),
  jump('jump.mp3'),
  
  // Düşman sesleri
  slimeDeath('167075__drminky__slime-land.wav'),
  enemyHit('hitHurt.wav'),
  enemyHit2('hitHurt-2.wav'),
  
  // Yetenek sesleri
  shieldBlock('223628__ctcollab__shield-slam-2.wav'),
  powerUp('powerUp.wav'),
  dash('random.wav'),
  
  // Pickup/Reward sesleri
  xpCollect('xp_collect.mp3'),
  coinCollect('pickupCoin.wav'),
  coinCollect2('pickupCoin-2.wav'),
  heal('644306__reincarnatedechoes__heart-collecthealing-retro.wav'),
  purchase('Cash Purchase Sound Effects.mp3'),
  
  // Level sesleri
  elevatorDing('588718__collierhs_colinlib__elevator-ding.wav'),
  levelComplete('level complete.wav');

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
  AudioPlayer? _bgmPlayer;
  int _currentPlayerIndex = 0;
  static const int _maxPlayers = 6;

  final Random _random = Random();

  bool _soundEnabled = true;
  double _volume = 0.6;
  double _sfxVolume = 0.8;
  double _musicVolume = 0.5;

  // Footstep için cooldown
  double _footstepCooldown = 0;
  static const double _footstepInterval = 0.25;

  // Footstep varyasyonları
  static const List<GameSound> _footstepSounds = [
    GameSound.footstep02,
    GameSound.footstep03,
    GameSound.footstep04,
    GameSound.footstep05,
    GameSound.footstep06,
    GameSound.footstep07,
  ];

  int _lastFootstepIndex = -1;

  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;
  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;

  /// Ses servisini başlat
  Future<void> initialize() async {
    // Hive'dan ayarları yükle
    try {
      final box = Hive.box('game_data');
      _soundEnabled = box.get('sound_enabled', defaultValue: true);
      _volume = box.get('master_volume', defaultValue: 0.6);
      _sfxVolume = box.get('sfx_volume', defaultValue: 0.8);
      _musicVolume = box.get('music_volume', defaultValue: 0.5);
    } catch (e) {
      debugPrint('Ses ayarları yüklenemedi: $e');
    }
    
    for (int i = 0; i < _maxPlayers; i++) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setPlayerMode(PlayerMode.lowLatency);
      _players.add(player);
    }
    
    // BGM Player
    _bgmPlayer = AudioPlayer();
    await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
    _updateBgmVolume();
  }

  /// Sesi aç/kapat
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    _saveSettings();
  }

  /// Genel ses seviyesini ayarla
  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _updateBgmVolume();
    _saveSettings();
  }

  /// SFX ses seviyesini ayarla
  void setSfxVolume(double vol) {
    _sfxVolume = vol.clamp(0.0, 1.0);
    _saveSettings();
  }

  /// Müzik ses seviyesini ayarla
  void setMusicVolume(double vol) {
    _musicVolume = vol.clamp(0.0, 1.0);
    _updateBgmVolume();
    _saveSettings();
  }
  
  void _updateBgmVolume() {
    if (_bgmPlayer != null) {
      final finalVolume = _soundEnabled ? (_volume * _musicVolume) : 0.0;
      _bgmPlayer!.setVolume(finalVolume.clamp(0.0, 1.0));
    }
  }
  
  /// Ayarları kaydet
  void _saveSettings() {
    try {
      final box = Hive.box('game_data');
      box.put('sound_enabled', _soundEnabled);
      box.put('master_volume', _volume);
      box.put('sfx_volume', _sfxVolume);
      box.put('music_volume', _musicVolume);
    } catch (e) {
      debugPrint('Ses ayarları kaydedilemedi: $e');
    }
  }

  // ==================== BGM ====================
  
  Future<void> playBackgroundMusic() async {
    if (_bgmPlayer == null) return;
    try {
      // Loop the specified mp3
      await _bgmPlayer!.play(AssetSource('sfx/music/audio-6.mp3'));
      _updateBgmVolume();
    } catch (e) {
      debugPrint('BGM çalma hatası: $e');
    }
  }
  
  Future<void> stopBackgroundMusic() async {
    await _bgmPlayer?.stop();
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

  /// Pitch randomizer ile ses çal
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
      final pitch = minPitch + _random.nextDouble() * (maxPitch - minPitch);

      await player.setVolume(finalVolume.clamp(0.0, 1.0));
      await player.setPlaybackRate(pitch);
      await player.play(AssetSource(sound.path));

      Future.delayed(const Duration(milliseconds: 500), () {
        player.setPlaybackRate(1.0);
      });
    } catch (e) {
      debugPrint('Oyun sesi çalma hatası (pitch): $e');
    }
  }

  // ==================== FOOTSTEP ====================
  
  void playFootstep(double dt) {
    _footstepCooldown -= dt;
    if (_footstepCooldown <= 0) {
      int newIndex;
      do {
        newIndex = _random.nextInt(_footstepSounds.length);
      } while (newIndex == _lastFootstepIndex && _footstepSounds.length > 1);
      _lastFootstepIndex = newIndex;

      playSoundWithPitchVariation(
        _footstepSounds[newIndex],
        minPitch: 0.85,
        maxPitch: 1.15,
        volumeMultiplier: 0.7,
      );
      _footstepCooldown = _footstepInterval;
    }
  }

  void resetFootstepCooldown() {
    _footstepCooldown = 0;
  }

  // ==================== COMBAT ====================

  Future<void> playSwordSwoosh() async {
    final sound = _random.nextBool() ? GameSound.swordSwoosh : GameSound.swordSwing;
    await playSoundWithPitchVariation(sound, minPitch: 0.9, maxPitch: 1.1, volumeMultiplier: 0.8);
  }

  Future<void> playSwordHit() async {
    final sound = _random.nextBool() ? GameSound.swordStab : GameSound.swordStab2;
    await playSoundWithPitchVariation(sound, minPitch: 0.85, maxPitch: 1.15, volumeMultiplier: 1.0);
  }
  
  Future<void> playEnemyHit() async {
    final sound = _random.nextBool() ? GameSound.enemyHit : GameSound.enemyHit2;
    await playSoundWithPitchVariation(sound, minPitch: 0.9, maxPitch: 1.2, volumeMultiplier: 0.7);
  }

  // ==================== PLAYER ====================
  
  Future<void> playPlayerHurt() async {
    final sound = _random.nextBool() ? GameSound.playerHurt : GameSound.playerHurt2;
    await playSoundWithPitchVariation(sound, minPitch: 0.9, maxPitch: 1.1, volumeMultiplier: 0.8);
  }
  
  Future<void> playPlayerDeath() async {
    await playSound(GameSound.playerDeath, volumeMultiplier: 1.0);
  }
  
  Future<void> playJump() async {
    await playSoundWithPitchVariation(GameSound.jump, minPitch: 0.95, maxPitch: 1.05, volumeMultiplier: 0.6);
  }

  // ==================== ENEMIES ====================
  
  Future<void> playSlimeDeath() async {
    await playSoundWithPitchVariation(GameSound.slimeDeath, minPitch: 0.8, maxPitch: 1.2, volumeMultiplier: 0.7);
  }
  
  Future<void> playEnemyDeath() async {
    // Genel düşman ölüm sesi
    await playSoundWithPitchVariation(GameSound.enemyHit, minPitch: 0.6, maxPitch: 0.8, volumeMultiplier: 0.9);
  }

  // ==================== ABILITIES ====================
  
  Future<void> playShieldBlock() async {
    await playSound(GameSound.shieldBlock, volumeMultiplier: 0.8);
  }
  
  Future<void> playPowerUp() async {
    await playSound(GameSound.powerUp, volumeMultiplier: 0.7);
  }
  
  Future<void> playDash() async {
    await playSoundWithPitchVariation(GameSound.dash, minPitch: 1.0, maxPitch: 1.3, volumeMultiplier: 0.6);
  }

  // ==================== PICKUPS ====================

  Future<void> playXpCollect() async {
    await playSoundWithPitchVariation(GameSound.xpCollect, minPitch: 1.2, maxPitch: 1.6, volumeMultiplier: 0.5);
  }
  
  Future<void> playCoinCollect() async {
    final sound = _random.nextBool() ? GameSound.coinCollect : GameSound.coinCollect2;
    await playSoundWithPitchVariation(sound, minPitch: 0.9, maxPitch: 1.1, volumeMultiplier: 0.6);
  }
  
  Future<void> playHeal() async {
    await playSound(GameSound.heal, volumeMultiplier: 0.7);
  }
  
  Future<void> playPurchase() async {
    await playSound(GameSound.purchase, volumeMultiplier: 0.6);
  }

  // ==================== LEVEL ====================
  
  Future<void> playElevatorDing() async {
    await playSound(GameSound.elevatorDing, volumeMultiplier: 0.8);
  }
  
  Future<void> playLevelComplete() async {
    await playSound(GameSound.levelComplete, volumeMultiplier: 0.9);
  }

  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
    _players.clear();
    _bgmPlayer?.dispose();
  }
}
