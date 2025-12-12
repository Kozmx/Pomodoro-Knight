import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TEST: Klavye için
import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/components/background.dart';
import 'package:pomodoro_knight/game/enemy/slime/slime.dart';
import 'package:pomodoro_knight/game/enemy/slime/bat.dart';
import 'package:pomodoro_knight/game/components/health_bar.dart';
import 'package:pomodoro_knight/game/components/level_indicator.dart';
import 'package:pomodoro_knight/game/components/level_manager.dart';
import 'package:pomodoro_knight/game/components/elevator.dart';

// ===================== TEST MODU =====================
// Bu bölümü silmek için "TEST:" araması yap ve kaldır
const bool _testModeEnabled = true; // TEST: false yaparak devre dışı bırak
// =====================================================

class FocusGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  late final Player player;
  late final JoystickComponent joystick;
  late final GameBackground background;
  late final LevelManager levelManager;

  // Button Logic
  bool _isAttackButtonPressed = false;
  double _buttonHoldTimer = 0.0;
  final double _shieldThreshold = 0.2; // Seconds to hold for shield

  // TEST: Klavye kontrolleri için
  final Set<LogicalKeyboardKey> _keysPressed = {};

  FocusGame() : super() {
    // Flame'in image prefix'ini assets/ olarak ayarla
    images.prefix = 'assets/';
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Joystick'i oluştur (HUD elemanı olarak kalacak)
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 20,
        paint: Paint()..color = Colors.grey.withOpacity(0.5),
      ),
      background: CircleComponent(
        radius: 50,
        paint: Paint()..color = Colors.grey.withOpacity(0.2),
      ),
      margin: const EdgeInsets.only(left: 30, bottom: 30),
    );

    camera.viewport.add(joystick);

    // Attack Button with Hold Logic
    final attackButton = HudButtonComponent(
      button: CircleComponent(
        radius: 30,
        paint: Paint()..color = Colors.red.withOpacity(0.5),
      ),
      margin: const EdgeInsets.only(right: 30, bottom: 30),
      onPressed: () {
        _isAttackButtonPressed = true;
        _buttonHoldTimer = 0;
      },
      onReleased: () {
        _isAttackButtonPressed = false;
        player.setShield(false);

        // If held for less than threshold, it's an attack
        if (_buttonHoldTimer < _shieldThreshold) {
          player.attack();
        }
        _buttonHoldTimer = 0;
      },
    );
    camera.viewport.add(attackButton);

    // Health Bar
    camera.viewport.add(HealthBar());

    // Level Indicator
    camera.viewport.add(LevelIndicator());

    // 2. Arka planı dünyaya ekle
    background = GameBackground();
    world.add(background);

    // 3. Oyuncuyu dünyaya ekle
    player = Player(joystick: joystick)
      ..position = Vector2(1000, 750); // Başlangıç pozisyonu (Map ortası)
    world.add(player);

    // 4. Level Manager'ı ekle
    levelManager = LevelManager();
    world.add(levelManager);

    // 5. Kamerayı oyuncuya kilitle
    camera.follow(player);

    // Kamera sınırlarını belirle (Arka plan dışına çıkmasın)
    camera.setBounds(
      Rectangle.fromLTRB(0, 0, GameBackground.worldWidth, GameBackground.worldHeight),
    );

    // TEST: Tüm düşmanları öldür butonu
    if (_testModeEnabled) {
      final killAllButton = HudButtonComponent(
        button: CircleComponent(
          radius: 25,
          paint: Paint()..color = Colors.purple.withOpacity(0.7),
          children: [
            TextComponent(
              text: '💀',
              position: Vector2(25, 25),
              anchor: Anchor.center,
              textRenderer: TextPaint(
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        margin: const EdgeInsets.only(right: 100, bottom: 30),
        onPressed: _killAllEnemies,
      );
      camera.viewport.add(killAllButton);
    }

    // Show Start Menu initially
    overlays.add('StartMenu');
    pauseEngine();
  }

  // Game over state
  bool _isGameOver = false;
  double _gameOverTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);

    // Handle Button Hold Logic
    if (_isAttackButtonPressed) {
      _buttonHoldTimer += dt;
      if (_buttonHoldTimer >= _shieldThreshold) {
        player.setShield(true);
      }
    }

    // TEST: Klavye ile hareket (ok tuşları + space)
    if (_testModeEnabled) {
      _handleKeyboardMovement();
    }

    // Check Game Over - 2 saniye bekle sonra popup göster
    if (player.currentHealth <= 0 && !_isGameOver) {
      _isGameOver = true;
      _gameOverTimer = 0;
    }
    
    if (_isGameOver) {
      _gameOverTimer += dt;
      if (_gameOverTimer >= 2.0) {
        pauseEngine();
        overlays.add('GameOver');
      }
    }
  }

  // TEST: Klavye kontrolleri
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!_testModeEnabled) return KeyEventResult.ignored;
    
    _keysPressed.clear();
    _keysPressed.addAll(keysPressed);
    
    // Space tuşu ile saldırı
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      player.attack();
      return KeyEventResult.handled;
    }
    
    // K tuşu ile tüm düşmanları öldür
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyK) {
      _killAllEnemies();
      return KeyEventResult.handled;
    }
    
    return KeyEventResult.handled;
  }

  // TEST: Klavye ile hareket
  void _handleKeyboardMovement() {
    double dx = 0;
    double dy = 0;
    
    if (_keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      dx = -1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      dx = 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      dy = -1; // Zıplama için
    }
    
    // TEST: Player'ın test input'unu ayarla
    player.testInput = Vector2(dx, dy);
  }

  // TEST: Tüm düşmanları öldür
  void _killAllEnemies() {
    print('TEST: Killing all enemies!');
    final enemies = world.children.whereType<Enemy>().toList();
    final flyingEnemies = world.children.whereType<FlyingEnemy>().toList();
    
    for (final enemy in enemies) {
      enemy.removeFromParent();
      levelManager.onEnemyKilled();
    }
    for (final enemy in flyingEnemies) {
      enemy.removeFromParent();
      levelManager.onEnemyKilled();
    }
  }

  void startGame() {
    overlays.remove('StartMenu');
    resumeEngine();
    levelManager.startLevel();
  }

  void resetGame() {
    // Reset game over state
    _isGameOver = false;
    _gameOverTimer = 0;
    
    player.currentHealth = player.maxHealth;
    player.position = Vector2(1000, 750);
    player.velocity = Vector2.zero();

    // Remove existing enemies and respawn
    world.children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    world.children.whereType<FlyingEnemy>().forEach(
      (e) => e.removeFromParent(),
    );
    world.children.whereType<Elevator>().forEach((e) => e.removeFromParent());

    // Restart current level
    levelManager.startLevel();

    overlays.remove('GameOver');
    resumeEngine();
  }
}
