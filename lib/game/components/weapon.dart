import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/enemy/slime/slime.dart';
import 'package:pomodoro_knight/game/enemy/slime/bat.dart';
import 'package:pomodoro_knight/game/enemy/flower/flower.dart';
import 'package:pomodoro_knight/game/components/damage_text.dart';

class Weapon extends PositionComponent with CollisionCallbacks {
  final double damageMultiplier;

  Weapon({
    required Vector2 position,
    required Vector2 size,
    this.damageMultiplier = 1.0,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
    // Debug visual - upgrade'e göre renk
    final upgradeColor = damageMultiplier > 1.0
        ? Colors.orange.withOpacity(0.5 + (damageMultiplier - 1.0) * 0.2)
        : Colors.yellow.withOpacity(0.5);
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = upgradeColor,
      ),
    );

    // Remove after 0.2 seconds
    Future.delayed(const Duration(milliseconds: 200), () {
      removeFromParent();
    });
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    // Base damage 10, çarpanla artırılmış
    final damage = 10.0 * damageMultiplier;
    
    if (other is Enemy) {
      other.takeDamage(damage);
      _showDamageText(other.position, damage);
    } else if (other is FlyingEnemy) {
      other.takeDamage(damage);
      _showDamageText(other.position, damage);
    } else if (other is FlowerEnemy) {
      other.takeDamage(damage);
      _showDamageText(other.position, damage);
    }
  }
  
  void _showDamageText(Vector2 enemyPosition, double damage) {
    final damageText = DamageText(
      position: enemyPosition.clone() + Vector2(0, -40),
      damage: damage,
      color: Colors.yellowAccent,
    );
    parent?.add(damageText);
  }
}
