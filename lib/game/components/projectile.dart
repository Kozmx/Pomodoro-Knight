import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/enemy/slime/slime.dart';
import 'package:pomodoro_knight/game/enemy/slime/bat.dart';
import 'package:pomodoro_knight/game/enemy/flower/flower.dart';

class Projectile extends PositionComponent with CollisionCallbacks {
  Vector2 velocity;
  static final _paint = Paint()..color = Colors.orange;
  static final _paintReflected = Paint()..color = Colors.cyanAccent;
  double lifeTime = 0;
  bool isReflected = false;

  Projectile({required Vector2 position, required this.velocity})
    : super(position: position, size: Vector2(10, 10)) {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      isReflected ? _paintReflected : _paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    lifeTime += dt;
    if (lifeTime > 3.0) {
      // Remove after 3 seconds
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player) {
      if (other.isShielding) {
        if (!isReflected) {
          velocity.negate();
          velocity.scale(1.5); // Reflect faster
          isReflected = true;
          lifeTime = 0; // Reset lifetime
        }
      } else {
        other.takeDamage(10, position);
        removeFromParent();
      }
    } else if (isReflected) {
      if (other is Enemy) {
        other.takeDamage();
        removeFromParent();
      } else if (other is FlyingEnemy) {
        other.takeDamage();
        removeFromParent();
      } else if (other is FlowerEnemy) {
        other.takeDamage();
        removeFromParent();
      }
    }
  }
}
