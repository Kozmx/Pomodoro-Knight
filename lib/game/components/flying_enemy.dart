import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/components/projectile.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

class FlyingEnemy extends PositionComponent
    with CollisionCallbacks, HasGameRef<FocusGame> {
  final Player player;
  static final _paint = Paint()..color = Colors.purpleAccent;
  double shootTimer = 0.0;
  final double shootInterval = 2.5;

  // Stats
  double maxHealth;
  double currentHealth;
  double damage;

  // AI
  final double detectionRange = 400.0; // Slightly larger range for flying
  bool isChasing = false;
  double patrolDirection = 1.0;
  double patrolTimer = 0.0;

  FlyingEnemy({required this.player, this.maxHealth = 20.0, this.damage = 10.0})
    : currentHealth = maxHealth;

  @override
  Future<void> onLoad() async {
    size = Vector2(30, 30);
    anchor = Anchor.center;
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // Triangle shape
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(path, _paint);

    // Optional: Health bar
    if (currentHealth < maxHealth) {
      canvas.drawRect(
        Rect.fromLTWH(0, -10, size.x, 5),
        Paint()..color = Colors.red.withOpacity(0.5),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, -10, size.x * (currentHealth / maxHealth), 5),
        Paint()..color = Colors.green,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    double distance = position.distanceTo(player.position);

    if (distance <= detectionRange) {
      isChasing = true;
      // Hover logic: Try to stay above the player
      // Target position: 80 units above player (Reachable by jump)
      double targetY = player.position.y - 80;
      double targetX = player.position.x;

      Vector2 targetPos = Vector2(targetX, targetY);
      Vector2 direction = (targetPos - position);
      double distToTarget = direction.length;

      // Smooth movement with max speed
      double moveSpeed = 150.0; // Constant speed approach

      if (distToTarget > 5) {
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
      // Patrol Logic (Flying)
      patrolTimer += dt;
      if (patrolTimer > 3.0) {
        patrolDirection *= -1;
        patrolTimer = 0;
      }
      position.x += 50 * patrolDirection * dt;
      // Bob up and down slightly
      position.y += 20 * dt * (patrolTimer % 1 > 0.5 ? 1 : -1);
    }

    // Separation Logic
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
      separation.scale(100.0); // Separation strength
      position += separation * dt;
    }
  }

  void shoot() {
    Vector2 direction = (player.position - position).normalized();
    final projectile = Projectile(
      position: position.clone(),
      velocity: direction * 250, // Projectile speed
    );
    parent?.add(projectile);
  }

  void takeDamage() {
    currentHealth -= 10;
    if (currentHealth <= 0) {
      gameRef.levelManager.onEnemyKilled();
      removeFromParent();
    }
  }
}
