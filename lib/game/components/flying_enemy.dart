import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/components/projectile.dart';

class FlyingEnemy extends PositionComponent with CollisionCallbacks {
  final Player player;
  static final _paint = Paint()..color = Colors.purpleAccent;
  double shootTimer = 0.0;
  final double shootInterval = 2.5;

  FlyingEnemy({required this.player});

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
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Hover logic: Try to stay above the player
    // Target position: 100 units above player (Lowered from 150 to make it hittable)
    double targetY = player.position.y - 100;
    double targetX = player.position.x; // Follow player X

    // Simple interpolation towards target
    double lerpSpeed = 2.0;
    position.x += (targetX - position.x) * lerpSpeed * dt;
    position.y += (targetY - position.y) * lerpSpeed * dt;

    // Shooting logic
    shootTimer += dt;
    if (shootTimer >= shootInterval) {
      shootTimer = 0;
      shoot();
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
    removeFromParent();
  }
}
