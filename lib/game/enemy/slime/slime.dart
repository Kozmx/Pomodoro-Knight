import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/cache.dart'; // For Images
import 'package:flame/sprite.dart';

import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

enum SlimeState {
  idle,
  moveLeft,
  moveRight,
  attackFront,
  attackLeft,
  attackRight,
  hurtFront,
  hurtLeft,
  hurtRight,
  death,
}

class Enemy extends SpriteAnimationGroupComponent<SlimeState>
    with CollisionCallbacks, HasGameRef<FocusGame> {
  final Player player;
  final double speed = 100;

  // Stats
  double maxHealth;
  double currentHealth;
  double damage;

  // AI
  final double detectionRange = 300.0;
  bool isChasing = false;
  double patrolDirection = 1.0;
  double patrolTimer = 0.0;

  // Animation State Logic
  bool _isAttacking = false;
  bool _isHurt = false;
  bool _isDead = false;

  Enemy({required this.player, this.maxHealth = 30.0, this.damage = 10.0})
    : currentHealth = maxHealth,
      super(size: Vector2(128, 128)); // Scaled up size

  @override
  Future<void> onLoad() async {
    // Load images
    final images = Images(prefix: 'assets/');
    final idleImage = await images.load('slime1/Slime1_Idle_with_shadow.png');
    final walkImage = await images.load('slime1/Slime1_Walk_with_shadow.png');
    final attackImage = await images.load(
      'slime1/Slime1_Attack_with_shadow.png',
    );
    final hurtImage = await images.load('slime1/Slime1_Hurt_with_shadow.png');
    final deathImage = await images.load('slime1/Slime1_Death_with_shadow.png');

    final srcSize = Vector2(64, 64);

    final idleSheet = SpriteSheet(image: idleImage, srcSize: srcSize);
    final walkSheet = SpriteSheet(image: walkImage, srcSize: srcSize);
    final attackSheet = SpriteSheet(image: attackImage, srcSize: srcSize);
    final hurtSheet = SpriteSheet(image: hurtImage, srcSize: srcSize);
    final deathSheet = SpriteSheet(image: deathImage, srcSize: srcSize);

    // Helper to create animation
    SpriteAnimation createAnim(SpriteSheet sheet, int row, {bool loop = true}) {
      return sheet.createAnimation(row: row, stepTime: 0.1, to: 6, loop: loop);
    }

    // Idle
    final idleAnim = createAnim(idleSheet, 0);

    // Walk
    final walkLeftAnim = createAnim(walkSheet, 2);
    final walkRightAnim = createAnim(walkSheet, 3);

    // Attack (One-shot)
    final attackFrontAnim = createAnim(attackSheet, 0, loop: false);
    final attackLeftAnim = createAnim(attackSheet, 2, loop: false);
    final attackRightAnim = createAnim(attackSheet, 3, loop: false);

    // Hurt (One-shot)
    final hurtFrontAnim = createAnim(hurtSheet, 0, loop: false);
    final hurtLeftAnim = createAnim(hurtSheet, 2, loop: false);
    final hurtRightAnim = createAnim(hurtSheet, 3, loop: false);

    // Death (One-shot)
    final deathAnim = createAnim(deathSheet, 0, loop: false);

    animations = {
      SlimeState.idle: idleAnim,
      SlimeState.moveLeft: walkLeftAnim,
      SlimeState.moveRight: walkRightAnim,
      SlimeState.attackFront: attackFrontAnim,
      SlimeState.attackLeft: attackLeftAnim,
      SlimeState.attackRight: attackRightAnim,
      SlimeState.hurtFront: hurtFrontAnim,
      SlimeState.hurtLeft: hurtLeftAnim,
      SlimeState.hurtRight: hurtRightAnim,
      SlimeState.death: deathAnim,
    };

    current = SlimeState.idle;
    anchor = const Anchor(0.5, 0.2);

    add(RectangleHitbox(position: Vector2(32, 32), size: Vector2(64, 64)));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // If dead, do nothing but wait for animation to finish
    if (_isDead) {
      if (animationTicker?.done() == true) {
        removeFromParent();
      }
      return;
    }

    // Handle One-Shot Animations (Hurt, Attack)
    if (_isHurt || _isAttacking) {
      if (animationTicker?.done() == true) {
        _isHurt = false;
        _isAttacking = false;
        // Reset to idle/move logic next frame
      } else {
        // Don't move while hurting or attacking
        return;
      }
    }

    double distance = position.distanceTo(player.position);
    double moveX = 0;

    if (distance <= detectionRange) {
      isChasing = true;
      if (distance > 45) {
        double directionX = (player.position.x - position.x).sign;
        moveX = directionX * speed * dt;
        position.x += moveX;
      }
    } else {
      isChasing = false;
      patrolTimer += dt;
      if (patrolTimer > 2.0) {
        patrolDirection *= -1;
        patrolTimer = 0;
      }
      moveX = speed * 0.5 * patrolDirection * dt;
      position.x += moveX;
    }

    // Update Animation State based on movement
    if (moveX < 0) {
      current = SlimeState.moveLeft;
    } else if (moveX > 0) {
      current = SlimeState.moveRight;
    } else {
      current = SlimeState.idle;
    }

    // Separation Logic
    _applySeparation(dt);
  }

  void _applySeparation(double dt) {
    final separationRadius = 50.0;
    Vector2 separation = Vector2.zero();
    int neighbors = 0;

    for (final other in gameRef.world.children.query<Enemy>()) {
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

  void takeDamage(double damage) {
    if (_isDead) return;

    currentHealth -= damage;
    if (currentHealth <= 0) {
      _isDead = true;
      current = SlimeState.death;
      gameRef.levelManager.onEnemyKilled();
    } else {
      _isHurt = true;
      _isAttacking = false; // Hurt interrupts attack

      // Determine direction for hurt animation
      if (player.position.x < position.x) {
        current = SlimeState.hurtLeft; // Hit from left (or facing left?)
        // Actually if player is to the left, enemy faces left usually.
        // Let's just use the current movement direction or default to front
        // If moving left, hurt left.
      } else {
        current = SlimeState.hurtRight;
      }
      // Reset ticker to ensure animation plays from start
      animationTicker?.reset();
    }
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
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player && !_isDead && !_isHurt && !_isAttacking) {
      // Hasar ver (takeDamage içinde knockback da var)
      other.takeDamage(damage, position);

      // Trigger Attack Animation
      _isAttacking = true;
      if (other.position.x < position.x) {
        current = SlimeState.attackLeft;
      } else {
        current = SlimeState.attackRight;
      }
      animationTicker?.reset();
    }
  }
}
