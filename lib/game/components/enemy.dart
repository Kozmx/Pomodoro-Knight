import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/components/weapon.dart';

import 'package:pomodoro_knight/game/focus_game.dart';

class Enemy extends PositionComponent
    with CollisionCallbacks, HasGameRef<FocusGame> {
  final Player player;
  static final _paint = Paint()..color = Colors.red;
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

  Enemy({required this.player, this.maxHealth = 30.0, this.damage = 10.0})
    : currentHealth = maxHealth;

  @override
  Future<void> onLoad() async {
    size = Vector2(40, 40);
    anchor = Anchor.center;
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);

    // Optional: Health bar above enemy
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
      // Chase Behavior
      isChasing = true;
      if (distance > 45) {
        // Only move on X axis
        double directionX = (player.position.x - position.x).sign;
        position.x += directionX * speed * dt;
      }
    } else {
      // Patrol Behavior
      isChasing = false;
      patrolTimer += dt;
      if (patrolTimer > 2.0) {
        patrolDirection *= -1;
        patrolTimer = 0;
      }
      position.x += speed * 0.5 * patrolDirection * dt;

      // Keep within bounds (optional, but good for patrol)
      // For now, just simple back and forth
    }

    // Separation Logic
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
            // Inverse square law or linear? Linear is simpler and often sufficient
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

    // Face direction
    if (isChasing) {
      if (player.position.x > position.x) {
        scale.x = 1;
      } else {
        scale.x = -1;
      }
    } else {
      scale.x = patrolDirection;
    }
  }

  void takeDamage() {
    currentHealth -= 10; // Weapon damage
    if (currentHealth <= 0) {
      gameRef.levelManager.onEnemyKilled();
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      other.takeKnockback(position);
      // Apply damage to player if needed, currently player handles health
    }
  }
}
