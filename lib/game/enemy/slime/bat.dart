import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';

import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/components/projectile.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

enum BatState { idle, attack, hurt, death }

class FlyingEnemy extends SpriteAnimationGroupComponent<BatState>
    with CollisionCallbacks, HasGameRef<FocusGame> {
  final Player player;
  double shootTimer = 0.0;
  final double shootInterval = 2.5;

  // Stats
  double maxHealth;
  double currentHealth;
  double damage;

  // AI
  final double detectionRange = 400.0;
  bool isChasing = false;
  double patrolDirection = 1.0;
  double patrolTimer = 0.0;

  // Animation Flags
  bool _isAttacking = false;
  bool _isHurt = false;
  bool _isDead = false;

  FlyingEnemy({required this.player, this.maxHealth = 20.0, this.damage = 10.0})
    : currentHealth = maxHealth,
      super(size: Vector2(90, 90)); // Scaled up

  @override
  Future<void> onLoad() async {
    final images = Images(prefix: 'assets/');

    // Load Sprites
    final idleImage = await images.load(
      'bat/SimpleEnemies Bat_Idle Spritesheet.png',
    );
    final attackImage = await images.load(
      'bat/SimpleEnemies Bat_Attack Spritesheet.png',
    );
    final hurtImage = await images.load(
      'bat/SimpleEnemies Bat_Hit Spritesheet.png',
    );
    final deathImage = await images.load(
      'bat/SimpleEnemies Bat_Death Spritesheet.png',
    );

    final srcSize = Vector2(32, 32);

    // Helper to create animation
    SpriteAnimation createAnim(Image image, {bool loop = true}) {
      final sheet = SpriteSheet(image: image, srcSize: srcSize);
      return sheet.createAnimation(row: 0, stepTime: 0.1, to: 4, loop: loop);
    }

    final idleAnim = createAnim(idleImage);
    final attackAnim = createAnim(attackImage, loop: false);
    final hurtAnim = createAnim(hurtImage, loop: false);
    final deathAnim = createAnim(deathImage, loop: false);

    animations = {
      BatState.idle: idleAnim,
      BatState.attack: attackAnim,
      BatState.hurt: hurtAnim,
      BatState.death: deathAnim,
    };

    current = BatState.idle;
    anchor = Anchor.center;

    // Adjust hitbox
    // 90x90 size. Let's make hitbox 45x45 centered.
    // (90 - 45) / 2 = 22.5
    add(RectangleHitbox(position: Vector2(22.5, 22.5), size: Vector2(45, 45)));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw Health Bar
    final barWidth = size.x * 0.5;
    final barHeight = 3.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -8.0;

    // Background (Red)
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      Paint()..color = const Color(0xFFFF0000),
    );

    // Health (Green)
    final healthPercent = (currentHealth / maxHealth).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
      Paint()..color = const Color(0xFF00FF00),
    );

    // Border (White)
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDead) {
      if (animationTicker?.done() == true) {
        removeFromParent();
      }
      return;
    }

    if (_isHurt || _isAttacking) {
      if (animationTicker?.done() == true) {
        _isHurt = false;
        _isAttacking = false;
        current = BatState.idle;
      } else {
        // Optional: Allow movement while attacking/hurting?
        // Usually better to pause or slow down.
        // For flying enemy, maybe keep moving but slower?
        // Let's pause for now to show the animation clearly.
        return;
      }
    }

    double distance = position.distanceTo(player.position);

    // Face Player
    if (player.position.x > position.x) {
      scale.x = 1; // Face Right
    } else {
      scale.x = -1; // Face Left
    }

    if (distance <= detectionRange) {
      isChasing = true;
      // Hover logic - oyuncunun biraz üstünde sabit dur, çok hızlı kaçmasın
      double targetY = player.position.y - 100; // Biraz daha yukarıda
      double targetX = player.position.x;

      Vector2 targetPos = Vector2(targetX, targetY);
      Vector2 direction = (targetPos - position);
      double distToTarget = direction.length;

      // Daha yavaş hareket - vurması kolay olsun
      double moveSpeed = 60.0; // 150'den 60'a düşürüldü

      if (distToTarget > 30) { // 5'ten 30'a - daha erken durur
        direction.normalize();
        position += direction * moveSpeed * dt;
      }

      // Shooting logic
      shootTimer += dt;
      if (shootTimer >= shootInterval) {
        shootTimer = 0;
        shoot();
      }
    } else {
      isChasing = false;
      patrolTimer += dt;
      if (patrolTimer > 3.0) {
        patrolDirection *= -1;
        patrolTimer = 0;
      }
      position.x += 50 * patrolDirection * dt;
      position.y += 20 * dt * (patrolTimer % 1 > 0.5 ? 1 : -1);

      // Face patrol direction
      scale.x = patrolDirection;
    }

    // Separation Logic
    _applySeparation(dt);
  }

  void _applySeparation(double dt) {
    final separationRadius = 40.0;
    Vector2 separation = Vector2.zero();
    int neighbors = 0;

    for (final other in gameRef.world.children.query<FlyingEnemy>()) {
      if (other != this) {
        double dist = position.distanceTo(other.position);
        if (dist < separationRadius) {
          Vector2 push = position - other.position;
          if (dist > 0) {
            push.normalize();
            push.scale(1.0 - dist / separationRadius);
            separation += push;
            neighbors++;
          }
        }
      }
    }

    if (neighbors > 0) {
      separation /= neighbors.toDouble();
      separation.scale(100.0);
      position += separation * dt;
    }
  }

  void shoot() {
    _isAttacking = true;
    current = BatState.attack;
    animationTicker?.reset();

    Vector2 direction = (player.position - position).normalized();
    final projectile = Projectile(
      position: position.clone(),
      velocity: direction * 250,
    );
    parent?.add(projectile);
  }

  void takeDamage() {
    if (_isDead) return;

    currentHealth -= 10;
    if (currentHealth <= 0) {
      _isDead = true;
      current = BatState.death;
      gameRef.levelManager.onEnemyKilled();
    } else {
      _isHurt = true;
      _isAttacking = false; // Hurt interrupts attack
      current = BatState.hurt;
      animationTicker?.reset();
    }
  }
}
