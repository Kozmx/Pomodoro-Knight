import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TEST: Klavye için
import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/components/background.dart';
import 'package:pomodoro_knight/game/components/ability_buttons.dart';
import 'package:pomodoro_knight/game/enemy/slime/slime.dart';
import 'package:pomodoro_knight/game/enemy/slime/bat.dart';
import 'package:pomodoro_knight/game/enemy/flower/flower.dart';
import 'package:pomodoro_knight/game/components/health_bar.dart';
import 'package:pomodoro_knight/game/components/level_manager.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';

// ===================== TEST MODU =====================
// Bu bölümü silmek için "TEST:" araması yap ve kaldır
const bool _testModeEnabled = true; // TEST: false yaparak devre dışı bırak
// =====================================================

class FocusGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  late final Player player;
  late final JoystickComponent joystick;
  late final GameBackground background;
  late final LevelManager levelManager;

  // Ability butonları
  late final SkillButton skillButton;
  late final DashButton dashButton;
  late final ShieldButton shieldButton;
  late final AttackButton attackButton;

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

    // ===== YENİ ABILITY BUTONLARI =====
    // Ana saldırı butonu (sağ alt)
    attackButton = AttackButton(
      position: Vector2(0, 0), // Margin ile ayarlanacak
      radius: 30,
    );

    // Dash butonu (saldırının solunda)
    dashButton = DashButton(position: Vector2(0, 0), radius: 22);

    // Kalkan butonu (saldırının üstünde)
    shieldButton = ShieldButton(position: Vector2(0, 0), radius: 22);

    // Skill butonu (sol üst çaprazda - XP ile dolan)
    skillButton = SkillButton(position: Vector2(0, 0), radius: 22);

    // Butonları viewport'a ekle (pozisyonlar onMount'ta ayarlanacak)
    camera.viewport.add(
      _AbilityButtonContainer(
        attackButton: attackButton,
        dashButton: dashButton,
        shieldButton: shieldButton,
        skillButton: skillButton,
      ),
    );

    // Health Bar
    camera.viewport.add(HealthBar());

    // Level Indicator
    // LevelIndicator kaldırıldı - kat bilgisi FLOOR COMPLETE'de gösterilecek

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
      Rectangle.fromLTRB(
        0,
        0,
        GameBackground.worldWidth,
        GameBackground.worldHeight,
      ),
    );

    // TEST: Debug kontrolleri sadece klavye ile (K tuşu ile öldür)
    // Ekranda buton YOK - alan temiz

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
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (!_testModeEnabled) return KeyEventResult.ignored;

    _keysPressed.clear();
    _keysPressed.addAll(keysPressed);

    // X tuşu ile kalkan (basılı tutunca açık)
    if (event.logicalKey == LogicalKeyboardKey.keyX) {
      if (event is KeyDownEvent) {
        player.setShield(true);
      } else if (event is KeyUpEvent) {
        player.setShield(false);
      }
      return KeyEventResult.handled;
    }

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

    // 1 tuşu ile Player 1
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.digit1) {
      player.switchCharacter(1);
      return KeyEventResult.handled;
    }

    // 2 tuşu ile Player 2
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.digit2) {
      player.switchCharacter(2);
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
    GameAudioService().playBackgroundMusic(); // Oyuna başlayınca müziği çal
  }

  void resetGame() {
    // Reset game over state
    _isGameOver = false;
    _gameOverTimer = 0;

    // Oyuncuyu yeniden canlandır
    player.respawn();
    player.position = Vector2(1000, 750);

    // Remove existing enemies
    world.children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    world.children.whereType<FlyingEnemy>().forEach(
      (e) => e.removeFromParent(),
    );
    world.children.whereType<FlowerEnemy>().forEach(
      (e) => e.removeFromParent(),
    );

    // Restart current level
    levelManager.startLevel();
    GameAudioService().playBackgroundMusic(); // Müziği tekrar başlat

    overlays.remove('GameOver');
    resumeEngine();
  }

  /// Düşman öldüğünde XP ekle (skill butonu için)
  void addXpToSkill(int amount) {
    // Her XP 0.10 progress ekler (10 XP = full = ~2 düşman)
    // Bu sayede her katta en az 1 skill kullanılabilir
    skillButton.addXp(amount * 0.10);
  }
}

/// Ability butonlarını düzenleyen container
class _AbilityButtonContainer extends PositionComponent
    with HasGameRef<FocusGame> {
  final AttackButton attackButton;
  final DashButton dashButton;
  final ShieldButton shieldButton;
  final SkillButton skillButton;

  _AbilityButtonContainer({
    required this.attackButton,
    required this.dashButton,
    required this.shieldButton,
    required this.skillButton,
  });

  @override
  Future<void> onLoad() async {
    // Viewport boyutlarını al
    var viewportSize = gameRef.camera.viewport.size;

    // Eğer viewport henüz hazır değilse (0,0 ise), makul bir varsayılan kullan
    // Bu, render krizlerini ve negatif pozisyonları engeller.
    if (viewportSize.x <= 0 || viewportSize.y <= 0) {
      viewportSize = Vector2(800, 400); // Standart bir fallback
    }

    // Buton boyutları
    const double attackRadius = 30;
    const double abilityRadius = 22;
    const double margin = 30;
    const double spacing = 12;

    // Ana saldırı butonu pozisyonu (sağ alt)
    final attackPos = Vector2(
      viewportSize.x - margin - attackRadius,
      viewportSize.y - margin - attackRadius,
    );

    // Dash butonu (saldırının solunda)
    final dashPos = Vector2(
      attackPos.x - attackRadius - spacing - abilityRadius,
      attackPos.y + (attackRadius - abilityRadius),
    );

    // Kalkan butonu (saldırının üstünde)
    final shieldPos = Vector2(
      attackPos.x,
      attackPos.y - attackRadius - spacing - abilityRadius,
    );

    // Skill butonu (sol üst çaprazda)
    final skillPos = Vector2(
      attackPos.x - attackRadius - spacing - abilityRadius,
      attackPos.y - attackRadius - spacing - abilityRadius,
    );

    // Pozisyonları ayarla
    attackButton.position = attackPos;
    dashButton.position = dashPos;
    shieldButton.position = shieldPos;
    skillButton.position = skillPos;

    // Butonları ekle
    add(attackButton);
    add(dashButton);
    add(shieldButton);
    add(skillButton);
  }
}
