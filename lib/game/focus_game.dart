import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/components/background.dart';
import 'package:pomodoro_knight/game/enemy/slime/slime.dart';
import 'package:pomodoro_knight/game/enemy/slime/bat.dart';
import 'package:pomodoro_knight/game/components/health_bar.dart';
import 'package:pomodoro_knight/game/components/level_indicator.dart';
import 'package:pomodoro_knight/game/components/level_manager.dart';
import 'package:pomodoro_knight/game/components/elevator.dart';

class FocusGame extends FlameGame with HasCollisionDetection {
  late final Player player;
  late final JoystickComponent joystick;
  late final StarBackground background;
  late final LevelManager levelManager;

  // Button Logic
  bool _isAttackButtonPressed = false;
  double _buttonHoldTimer = 0.0;
  final double _shieldThreshold = 0.2; // Seconds to hold for shield

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
    background = StarBackground();
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
      Rectangle.fromLTRB(0, 0, background.size.x, background.size.y),
    );

    // Show Start Menu initially
    overlays.add('StartMenu');
    pauseEngine();
  }

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

    // Check Game Over
    if (player.currentHealth <= 0) {
      pauseEngine();
      overlays.add('GameOver');
    }
  }

  void startGame() {
    overlays.remove('StartMenu');
    resumeEngine();
    levelManager.startLevel();
  }

  void resetGame() {
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
