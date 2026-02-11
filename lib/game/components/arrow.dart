import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/enemy/slime/slime.dart';
import 'package:pomodoro_knight/game/enemy/slime/bat.dart';
import 'package:pomodoro_knight/game/enemy/flower/flower.dart';
import 'package:pomodoro_knight/game/components/damage_text.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';

/// Player tarafından ateşlenen ok (arrow) projectile
class Arrow extends PositionComponent with CollisionCallbacks {
  final Vector2 velocity;
  final double damage;
  final bool isCritical;
  final Color arrowColor;
  final String specialEffect;
  
  final GameAudioService _audioService = GameAudioService();
  double lifeTime = 0;
  double _rotation = 0;
  bool _hasHit = false;
  
  // Pierce için (Thunder Crossbow)
  int pierceCount = 0;
  final int maxPierce;

  Arrow({
    required Vector2 position,
    required this.velocity,
    required this.damage,
    this.isCritical = false,
    this.arrowColor = Colors.brown,
    this.specialEffect = 'None',
    this.maxPierce = 0,
  }) : super(position: position, size: Vector2(24, 8)) {
    anchor = Anchor.center;
    // Ok yönüne göre rotasyon
    _rotation = atan2(velocity.y, velocity.x);
  }

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_rotation);
    canvas.translate(-size.x / 2, -size.y / 2);
    
    // Ok gövdesi
    final bodyPaint = Paint()..color = arrowColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.y / 4, size.x * 0.7, size.y / 2),
        const Radius.circular(2),
      ),
      bodyPaint,
    );
    
    // Ok ucu (üçgen)
    final tipPath = Path()
      ..moveTo(size.x * 0.7, 0)
      ..lineTo(size.x, size.y / 2)
      ..lineTo(size.x * 0.7, size.y)
      ..close();
    
    final tipPaint = Paint()..color = arrowColor.withOpacity(0.9);
    canvas.drawPath(tipPath, tipPaint);
    
    // Ok tüyleri
    final featherPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(4, 0),
      Offset(0, size.y / 2),
      featherPaint,
    );
    canvas.drawLine(
      Offset(4, size.y),
      Offset(0, size.y / 2),
      featherPaint,
    );
    
    // Critical ise parlama efekti
    if (isCritical) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        12,
        Paint()
          ..color = Colors.yellow.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    
    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    position += velocity * dt;
    
    // Hafif yerçekimi efekti (opsiyonel)
    // velocity.y += 50 * dt;
    // _rotation = atan2(velocity.y, velocity.x);
    
    lifeTime += dt;
    if (lifeTime > 3.0) {
      removeFromParent();
    }
    
    // Ekran dışına çıktıysa kaldır
    if (position.x < -50 || position.x > 2100 || position.y < -50 || position.y > 900) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (_hasHit && maxPierce <= pierceCount) return;

    bool hitEnemy = false;

    if (other is Enemy) {
      other.takeDamage(damage);
      _showDamageText(other.position, damage, isCritical);
      hitEnemy = true;
      _applySpecialEffect(other);
    } else if (other is FlyingEnemy) {
      other.takeDamage(damage);
      _showDamageText(other.position, damage, isCritical);
      hitEnemy = true;
    } else if (other is FlowerEnemy) {
      other.takeDamage(damage);
      _showDamageText(other.position, damage, isCritical);
      hitEnemy = true;
    }

    if (hitEnemy) {
      _audioService.playEnemyHit();
      
      // Pierce kontrolü
      if (maxPierce > 0 && pierceCount < maxPierce) {
        pierceCount++;
        // Devam et, kaldırma
      } else {
        _hasHit = true;
        removeFromParent();
      }
    }
  }

  void _showDamageText(Vector2 enemyPosition, double damage, bool isCritical) {
    final damageText = DamageText(
      position: enemyPosition.clone() + Vector2(0, -40),
      damage: damage,
      isCritical: isCritical,
    );
    parent?.add(damageText);
  }
  
  void _applySpecialEffect(dynamic enemy) {
    // Special effect uygulamaları burada yapılabilir
    // Örn: Burn, Slow efektleri
    if (specialEffect.contains('Burn')) {
      // Burn damage over time
    } else if (specialEffect.contains('Slow')) {
      // Slow enemy movement
    }
  }
}
