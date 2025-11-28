import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/components/weapon.dart';

class Enemy extends PositionComponent with CollisionCallbacks {
  final Player player;
  static final _paint = Paint()..color = Colors.red;
  final double speed = 100;

  Enemy({required this.player});

  @override
  Future<void> onLoad() async {
    size = Vector2(40, 40);
    anchor = Anchor.center;
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    double distance = position.distanceTo(player.position);
    // Stop if too close (prevent overlapping)
    if (distance > 45) {
      Vector2 direction = (player.position - position).normalized();
      position += direction * speed * dt;
    }
    
    // Face player (optional visual tweak)
    if (player.position.x > position.x) {
      scale.x = 1;
    } else {
      scale.x = -1;
    }
  }

  void takeDamage() {
    removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      other.takeKnockback(position);
    }
  }
}
