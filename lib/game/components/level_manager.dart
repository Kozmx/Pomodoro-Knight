import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/background.dart';
import 'package:pomodoro_knight/game/components/elevator.dart';
import 'package:pomodoro_knight/game/components/game_effects.dart';
import 'package:pomodoro_knight/game/enemy/slime/slime.dart';
import 'package:pomodoro_knight/game/enemy/slime/bat.dart';
import 'package:pomodoro_knight/game/enemy/flower/flower.dart';
import 'package:pomodoro_knight/game/enemy/boss/slime_king.dart';
import 'package:pomodoro_knight/game/focus_game.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';

import 'package:hive_flutter/hive_flutter.dart';

enum LevelState { playing, transitioning, bossFight }

class LevelManager extends Component with HasGameRef<FocusGame> {
  int currentLevel = 1;
  int enemiesKilled = 0;
  int totalEnemies = 0;
  LevelState state = LevelState.playing;
  
  // Boss sistemi
  bool get isBossFloor => currentLevel % 10 == 0 && currentLevel > 0;
  SlimeKing? _currentBoss;
  
  // Asansör hazır bildirimi
  ElevatorReadyIndicator? _elevatorIndicator;

  final Random _rnd = Random();

  @override
  Future<void> onLoad() async {
    print("LevelManager: onLoad started");
    try {
      await _loadLevel();
      print("LevelManager: Level loaded: $currentLevel");
    } catch (e) {
      print("LevelManager: Error loading level: $e");
      currentLevel = 1;
    }
    // Don't start level automatically here, wait for Start Menu
    // startLevel();
  }

  Future<void> _loadLevel() async {
    final box = Hive.box('game_data');
    currentLevel = box.get('currentLevel', defaultValue: 1);
  }

  Future<void> _saveLevel() async {
    final box = Hive.box('game_data');
    await box.put('currentLevel', currentLevel);

    final maxLevel = box.get('maxLevel', defaultValue: 1);
    if (currentLevel > maxLevel) {
      await box.put('maxLevel', currentLevel);
    }
  }

  // Rampa başlangıç X pozisyonu (sabit)
  static const double rampStartX = 1200; // Mapin ortasının biraz sağı
  static const double platformY = 600;
  
  // Asansör spawn edildi mi?
  bool _elevatorSpawned = false;

  void startLevel() {
    print("LevelManager: startLevel called for level $currentLevel");
    enemiesKilled = 0;
    _elevatorSpawned = false;
    
    // Canı fulle
    gameRef.player.currentHealth = gameRef.player.maxHealth;

    // Boss katı mı?
    if (isBossFloor) {
      state = LevelState.bossFight;
      print("LevelManager: BOSS FLOOR! Spawning boss...");
      totalEnemies = 1;
      
      // Yapıları spawn et
      _spawnStructures();
      
      // Boss spawn et
      _spawnBoss();
      
      // Oyuncuyu spawn et
      _spawnPlayerOnPlatform();
      return;
    }
    
    state = LevelState.playing;

    // Calculate enemies for this level (simple progression)
    // Azaltılmış düşman sayıları - daha az iç içe girme için
    int enemyCount = 1 + (currentLevel ~/ 2); // Önceki: 2 + currentLevel
    int flyingEnemyCount = 1 + (currentLevel ~/ 3); // Önceki: 1 + currentLevel ~/ 2
    int flowerCount = currentLevel ~/ 3; // Önceki: currentLevel ~/ 2
    totalEnemies = enemyCount + flyingEnemyCount + flowerCount;

    print(
      "LevelManager: Spawning $enemyCount ground, $flyingEnemyCount flying, $flowerCount flower enemies",
    );

    // Rampa, platform ve kapıyı spawn et (asansör hariç - düşmanlar ölünce gelecek)
    _spawnStructures();
    
    _spawnEnemies(enemyCount, flyingEnemyCount, flowerCount);
    
    // Oyuncuyu platformda spawn et
    _spawnPlayerOnPlatform();
  }
  
  /// Boss spawn et
  void _spawnBoss() {
    final bossLevel = (currentLevel / 10).floor().toDouble();
    _currentBoss = SlimeKing(
      player: gameRef.player,
      level: bossLevel,
    )..position = Vector2(400, 700); // Sol tarafta spawn
    
    gameRef.world.add(_currentBoss!);
    
    // Boss fight sesi
    GameAudioService().playElevatorDing();
  }
  
  /// Boss öldürüldüğünde çağrılır
  void onBossKilled() {
    print("LevelManager: BOSS KILLED!");
    _currentBoss = null;
    state = LevelState.playing;
    _spawnElevator();
  }

  void _spawnPlayerOnPlatform() {
    // Oyuncuyu platform üzerinde spawn et (sağ tarafta)
    final spawnX = GameBackground.worldWidth - 150;
    final spawnY = platformY - gameRef.player.size.y / 2 - 10;
    gameRef.player.position = Vector2(spawnX, spawnY);
    gameRef.player.velocity = Vector2.zero();
    gameRef.player.canMove = true;
  }

  // Rastgele oluşturulan platformların pozisyonları (çiçekler için)
  final List<Vector2> _platformPositions = [];

  void _spawnStructures() {
    // Önce eski yapıları temizle
    gameRef.world.children.whereType<Ramp>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Platform>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Elevator>().forEach((e) => e.removeFromParent());
    
    // Platform pozisyonlarını temizle
    _platformPositions.clear();
    
    // ===== ANA RAMPA VE PLATFORM (sağ taraf - asansör için) =====
    // Rampa: yerden platforma çıkış
    final ramp = Ramp(
      startPos: Vector2(rampStartX, 800),
      endPos: Vector2(rampStartX + 300, platformY),
    );
    gameRef.world.add(ramp);
    
    // Platform: rampa ucundan mapin sağ sonuna kadar
    final platformStartX = rampStartX + 300;
    final platformWidth = GameBackground.worldWidth - platformStartX - 20;
    final platform = Platform(
      pos: Vector2(platformStartX, platformY),
      width: platformWidth,
    );
    gameRef.world.add(platform);
    
    // ===== RASTGELE PLATFORMLAR (savaş alanında - sol taraf) =====
    _spawnRandomPlatforms();
    
    // Asansör BAŞLANGIÇTA YOK - düşmanlar ölünce spawn olacak
  }
  
  void _spawnRandomPlatforms() {
    // Karakter fizik değerleri (player.dart'tan)
    const double jumpForce = 500;
    const double gravity = 1000;
    // Maksimum zıplama yüksekliği: h = v² / (2g) = 500² / 2000 = 125 piksel
    const double maxJumpHeight = (jumpForce * jumpForce) / (2 * gravity);
    const double safeJumpHeight = maxJumpHeight * 0.85; // ~106 piksel - platformlar arası güvenli mesafe
    
    // Platform sayısı: 2-3 arası (azaltıldı)
    final platformCount = 2 + _rnd.nextInt(2); // 2 veya 3
    
    // Platform spawn alanı
    final minX = 100.0;
    final maxX = rampStartX - 200; // Rampa öncesi
    
    // Y pozisyonları - yerden (800) yukarı doğru
    final groundY = 800.0;
    
    // Minimum platform arası mesafeler (artırıldı - iç içe girmesin)
    final minXDistance = 180.0; // 100'den 180'e
    final minYDistance = 80.0;  // Yeni - Y mesafesi de kontrol
    
    // Platformları oluştur
    List<Rect> existingPlatforms = []; // Platform alanları (overlap kontrolü için)
    
    // İlk platform - yerden zıplanabilir
    double firstY = groundY - 80 - _rnd.nextDouble() * 40; // 650-720 arası
    double firstX = minX + 50 + _rnd.nextDouble() * 200;
    double firstWidth = 150 + _rnd.nextDouble() * 50;
    
    final firstPlatform = Platform(pos: Vector2(firstX, firstY), width: firstWidth);
    gameRef.world.add(firstPlatform);
    existingPlatforms.add(Rect.fromLTWH(firstX, firstY - 20, firstWidth, 40));
    _platformPositions.add(Vector2(firstX + firstWidth / 2, firstY));
    print("LevelManager: Platform 1 at (${firstX.toInt()}, ${firstY.toInt()})");
    
    // Sonraki platformlar
    for (int i = 1; i < platformCount; i++) {
      double x, y, width;
      int attempts = 0;
      bool validPosition = false;
      
      do {
        // Rastgele pozisyon
        x = minX + _rnd.nextDouble() * (maxX - minX - 150);
        y = groundY - 80 - _rnd.nextDouble() * (safeJumpHeight + 50);
        width = 140 + _rnd.nextDouble() * 60;
        
        // Y sınırları
        if (y < 500) y = 500 + _rnd.nextDouble() * 50;
        if (y > groundY - 70) y = groundY - 80;
        
        // Overlap kontrolü - mevcut platformlarla çakışma
        final newRect = Rect.fromLTWH(x - 30, y - 50, width + 60, 100);
        validPosition = true;
        
        for (final existingRect in existingPlatforms) {
          if (newRect.overlaps(existingRect)) {
            validPosition = false;
            break;
          }
          
          // Minimum X ve Y mesafesi kontrolü
          final xDist = (x + width/2 - existingRect.center.dx).abs();
          final yDist = (y - existingRect.center.dy).abs();
          
          if (xDist < minXDistance && yDist < minYDistance) {
            validPosition = false;
            break;
          }
        }
        
        // Zıplanabilirlik kontrolü - en az bir platformdan veya yerden
        if (validPosition) {
          bool reachable = false;
          
          // Yerden zıplanabilir mi?
          if (y >= groundY - safeJumpHeight - 20) {
            reachable = true;
          }
          
          // Başka platformdan zıplanabilir mi?
          for (final existingRect in existingPlatforms) {
            final yDiff = existingRect.center.dy - y;
            if (yDiff.abs() <= safeJumpHeight && yDiff >= -30) {
              reachable = true;
              break;
            }
          }
          
          if (!reachable) validPosition = false;
        }
        
        attempts++;
      } while (!validPosition && attempts < 50);
      
      if (validPosition) {
        final newPlatform = Platform(pos: Vector2(x, y), width: width);
        gameRef.world.add(newPlatform);
        existingPlatforms.add(Rect.fromLTWH(x - 30, y - 50, width + 60, 100));
        _platformPositions.add(Vector2(x + width / 2, y));
        print("LevelManager: Platform ${i+1} at (${x.toInt()}, ${y.toInt()})");
      }
    }
  }

  void _spawnEnemies(int ground, int flying, int flowers) {
    final playerPos = gameRef.player.position;
    final minDistance = 400.0;

    // Difficulty Scaling
    // Base HP: 30, +10 per level
    // Base Damage: 10, +2 per level (passed to enemy, though enemy deals damage via collision currently)
    final double enemyHealth = 30.0 + (currentLevel - 1) * 10.0;
    final double enemyDamage = 10.0 + (currentLevel - 1) * 2.0;

    // Düşmanların spawn olabileceği alan (rampa/platform bölgesi HARİÇ)
    // Rampa x=1200'de başlıyor, onun solunda spawn olsunlar
    final double maxSpawnX = rampStartX - 100; // Rampa öncesine kadar

    // Spawn Ground Enemies
    for (int i = 0; i < ground; i++) {
      Vector2 spawnPos;
      int attempts = 0;
      do {
        spawnPos = Vector2(100 + _rnd.nextDouble() * (maxSpawnX - 100), 750);
        attempts++;
      } while (spawnPos.distanceTo(playerPos) < minDistance && attempts < 20);

      print(
        "LevelManager: Spawning Ground Enemy at $spawnPos after $attempts attempts",
      );

      gameRef.world.add(
        Enemy(
          player: gameRef.player,
          maxHealth: enemyHealth,
          damage: enemyDamage,
        )..position = spawnPos,
      );
    }

    // Spawn Flying Enemies
    for (int i = 0; i < flying; i++) {
      Vector2 spawnPos;
      int attempts = 0;
      do {
        spawnPos = Vector2(
          100 + _rnd.nextDouble() * (maxSpawnX - 100),
          300 + _rnd.nextDouble() * 300,
        );
        attempts++;
      } while (spawnPos.distanceTo(playerPos) < minDistance && attempts < 20);

      print(
        "LevelManager: Spawning Flying Enemy at $spawnPos after $attempts attempts",
      );

      gameRef.world.add(
        FlyingEnemy(
          player: gameRef.player,
          maxHealth: enemyHealth * 0.8, // Flying enemies have less HP
          damage: enemyDamage,
        )..position = spawnPos,
      );
    }
    
    // Spawn Flower Enemies (rastgele oluşturulan platformların üzerinde)
    for (int i = 0; i < flowers && i < _platformPositions.length; i++) {
      final spawnPos = _platformPositions[i].clone();
      
      print("LevelManager: Spawning Flower Enemy at $spawnPos");

      gameRef.world.add(
        FlowerEnemy(
          player: gameRef.player,
          maxHealth: enemyHealth * 0.7, // Çiçekler daha az HP
          damage: enemyDamage * 0.8,
        )..position = spawnPos,
      );
    }
  }

  void onEnemyKilled() {
    enemiesKilled++;
    if (enemiesKilled >= totalEnemies) {
      _spawnElevator();
    }
  }

  void _spawnElevator() {
    // Asansörü spawn et (sadece bir kere)
    if (!_elevatorSpawned) {
      _elevatorSpawned = true;
      final elevatorX = GameBackground.worldWidth - 80;
      final elevator = Elevator()
        ..position = Vector2(elevatorX, platformY);
      gameRef.world.add(elevator);
      print("LevelManager: Elevator spawned!");
      
      // Asansör hazır sesi
      GameAudioService().playElevatorDing();
      
      // Asansör hazır bildirimi göster
      _elevatorIndicator = ElevatorReadyIndicator(
        position: Vector2(elevatorX, platformY - 80),
      );
      gameRef.world.add(_elevatorIndicator!);
    }
  }

  void startAscension() {
    if (state == LevelState.transitioning) return;
    state = LevelState.transitioning;

    // Asansör bildirimini kaldır
    _elevatorIndicator?.dismiss();
    _elevatorIndicator = null;

    // Disable player movement
    gameRef.player.canMove = false;

    // 1. Zoom In (Smoothly)
    gameRef.add(_ZoomEffect(2.0, 2.0, curve: Curves.easeInOut));

    // 2. Animate Background (Simulate going up)
    // gameRef.background.scrollSpeed = 500.0; // Disabled for static background

    // 3. Show Menu after 2 seconds (asansör animasyonu için bekle)
    Future.delayed(const Duration(seconds: 2), () {
      if (state == LevelState.transitioning) {
        gameRef.overlays.add('ElevatorMenu');
      }
    });
  }

  void continueToNextLevel() {
    gameRef.overlays.remove('ElevatorMenu');

    // Wait a moment for zoom out or just proceed
    _nextLevel();
  }

  void _nextLevel() {
    currentLevel++;
    _saveLevel();

    // Level complete sesi
    GameAudioService().playLevelComplete();

    // Kat geçiş animasyonu göster
    final overlay = LevelTransitionOverlay(
      level: currentLevel,
      screenSize: gameRef.size,
    );
    gameRef.camera.viewport.add(overlay);

    // Start new level (bu fonksiyon içinde yapılar temizlenip yenileri ekleniyor + oyuncu platformda spawn)
    startLevel();

    // Zoom Out (Smoothly)
    gameRef.add(_ZoomEffect(1.0, 1.5, curve: Curves.easeOut));
  }
}

class _ZoomEffect extends Component with HasGameRef<FocusGame> {
  final double targetZoom;
  final double duration;
  final Curve curve;
  double _timer = 0;
  double _startZoom = 1.0;

  _ZoomEffect(this.targetZoom, this.duration, {this.curve = Curves.linear});

  @override
  Future<void> onLoad() async {
    _startZoom = gameRef.camera.viewfinder.zoom;
  }

  @override
  void update(double dt) {
    _timer += dt;
    double t = (_timer / duration).clamp(0.0, 1.0);
    double curveValue = curve.transform(t);
    gameRef.camera.viewfinder.zoom =
        _startZoom + (targetZoom - _startZoom) * curveValue;

    if (t >= 1.0) removeFromParent();
  }
}
