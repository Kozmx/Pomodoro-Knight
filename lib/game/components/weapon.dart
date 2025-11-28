import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/enemy.dart';
import 'package:pomodoro_knight/game/components/flying_enemy.dart';

class Weapon extends PositionComponent with CollisionCallbacks {
  Weapon({required Vector2 position, required Vector2 size}) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
    // Debug visual
    add(RectangleComponent(size: size, paint: Paint()..color = Colors.yellow.withOpacity(0.5)));
    
    // Remove after 0.2 seconds
    Future.delayed(const Duration(milliseconds: 200), () {
      removeFromParent();
    });
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Enemy) {
      other.takeDamage();
    } else if (other is FlyingEnemy) {
      other.takeDamage();
    }
  }
}
