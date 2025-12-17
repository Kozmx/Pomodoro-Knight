import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/components/projectile.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

/// Sabit duran, projektil fırlatan çiçek düşmanı
class FlowerEnemy extends PositionComponent
    with CollisionCallbacks, HasGameRef<FocusGame> {
  final Player player;
  
  // Stats
  double maxHealth;
  double currentHealth;
  double damage;
  
  // Shooting
  double shootTimer = 0.0;
  final double shootInterval = 2.0; // 2 saniyede bir ateş
  final double detectionRange = 500.0;
  
  // State flags
  bool _isAttacking = false;
  bool _isHurt = false;
  bool _isDead = false;
  double _hurtTimer = 0;
  double _attackTimer = 0;
  double _deathTimer = 0;

  FlowerEnemy({
    required this.player,
    this.maxHealth = 25.0,
    this.damage = 8.0,
  }) : currentHealth = maxHealth,
       super(size: Vector2(80, 80));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.bottomCenter;

    // Hitbox
    add(RectangleHitbox(
      position: Vector2(15, 20),
      size: Vector2(50, 60),
    ));
  }

  @override
  void render(Canvas canvas) {
    // Çiçek çizimi (sprite yerine custom çizim)
    final stemPaint = Paint()..color = Colors.green.shade700;
    final petalPaint = Paint()
      ..color = _isDead ? Colors.grey : (_isAttacking ? Colors.red.shade400 : Colors.pink.shade400);
    final centerPaint = Paint()..color = Colors.yellow.shade600;
    
    // Gövde (sap)
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 5, size.y * 0.4, 10, size.y * 0.6),
      stemPaint,
    );
    
    // Yapraklar
    final leafPaint = Paint()..color = Colors.green.shade500;
    canvas.drawOval(
      Rect.fromLTWH(size.x / 2 - 25, size.y * 0.6, 20, 10),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.x / 2 + 5, size.y * 0.55, 20, 10),
      leafPaint,
    );
    
    // Taç yaprakları (petals)
    final centerX = size.x / 2;
    final centerY = size.y * 0.25;
    final petalRadius = 15.0;
    
    for (int i = 0; i < 6; i++) {
      final px = centerX + petalRadius * 1.2 * (i.isEven ? 1 : -1) * (i % 3 == 0 ? 0.3 : 1);
      final py = centerY + (i < 3 ? -petalRadius : petalRadius * 0.5);
      canvas.drawCircle(Offset(px, py), petalRadius, petalPaint);
    }
    
    // Merkez
    canvas.drawCircle(Offset(centerX, centerY), 12, centerPaint);
    
    // Gözler (kızgın görünüm)
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(centerX - 5, centerY - 2), 3, eyePaint);
    canvas.drawCircle(Offset(centerX + 5, centerY - 2), 3, eyePaint);
    
    // Kaşlar (kızgın)
    final browPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centerX - 8, centerY - 8),
      Offset(centerX - 2, centerY - 6),
      browPaint,
    );
    canvas.drawLine(
      Offset(centerX + 8, centerY - 8),
      Offset(centerX + 2, centerY - 6),
      browPaint,
    );
    
    // Health bar
    if (!_isDead) {
      final barWidth = size.x * 0.6;
      final barHeight = 4.0;
      final barX = (size.x - barWidth) / 2;
      final barY = -10.0;
      
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
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDead) {
      // Ölüm animasyonu bittikten sonra kaldır
      _deathTimer += dt;
      if (_deathTimer > 0.5) {
        removeFromParent();
      }
      return;
    }

    // Timer-based state management
    if (_isHurt) {
      _hurtTimer -= dt;
      if (_hurtTimer <= 0) {
        _isHurt = false;
      }
      return;
    }
    
    if (_isAttacking) {
      _attackTimer -= dt;
      if (_attackTimer <= 0) {
        _isAttacking = false;
      }
    }

    // Oyuncuya bak
    if (player.position.x < position.x) {
      scale.x = -1; // Sola bak
    } else {
      scale.x = 1; // Sağa bak
    }

    double distance = position.distanceTo(player.position);

    if (distance <= detectionRange) {
      shootTimer += dt;
      if (shootTimer >= shootInterval) {
        shootTimer = 0;
        shoot();
      }
    }
  }

  void shoot() {
    _isAttacking = true;
    _attackTimer = 0.3;

    // Projektil oluştur
    final direction = (player.position - position).normalized();
    final projectileSpeed = 200.0;
    final projectileVelocity = direction * projectileSpeed;

    // Çiçeğin merkezinden fırlat
    final spawnPos = position.clone() + Vector2(0, -size.y * 0.5);

    final projectile = Projectile(
      position: spawnPos,
      velocity: projectileVelocity,
    );

    gameRef.world.add(projectile);
  }

  void takeDamage() {
    if (_isDead) return;

    currentHealth -= 10;
    if (currentHealth <= 0) {
      currentHealth = 0;
      _isDead = true;
      _deathTimer = 0;
      
      // LevelManager'a bildir
      gameRef.levelManager.onEnemyKilled();
    } else {
      _isHurt = true;
      _isAttacking = false;
      _hurtTimer = 0.3;
    }
  }

}
