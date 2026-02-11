import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/focus_game.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';

/// Boss durumları
enum BossState {
  idle,          // Bekliyor
  charging,      // Saldırıya hazırlanıyor
  attacking,     // Saldırı fırlatıyor
  vulnerable,    // Savunmasız - oyuncu saldırabilir
  stunned,       // Sersemletilmiş
  death,         // Ölüyor
}

/// Tüm boss'lar için base class
abstract class BossBase extends PositionComponent
    with CollisionCallbacks, HasGameRef<FocusGame> {
  final Player player;
  
  // Stats
  final double maxHealth;
  double currentHealth;
  final double baseDamage;
  final String bossName;
  
  // State
  BossState currentState = BossState.idle;
  
  // Timing
  double stateTimer = 0;
  double attackCooldown = 0;
  double stunDuration = 0;
  double vulnerableDuration = 0;
  
  // Flags
  bool isDead = false;
  int attackPattern = 0;
  
  // Audio
  final GameAudioService _audioService = GameAudioService();
  
  BossBase({
    required this.player,
    required this.maxHealth,
    required this.baseDamage,
    required this.bossName,
    required Vector2 size,
  }) : currentHealth = maxHealth, super(size: size);

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    // Büyük hitbox - Boss'a vurulabilsin
    add(RectangleHitbox(
      position: Vector2(size.x * 0.1, size.y * 0.1),
      size: Vector2(size.x * 0.8, size.y * 0.8),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isDead) return;
    
    stateTimer += dt;
    
    // State machine
    switch (currentState) {
      case BossState.idle:
        updateIdle(dt);
        break;
      case BossState.charging:
        updateCharging(dt);
        break;
      case BossState.attacking:
        updateAttacking(dt);
        break;
      case BossState.vulnerable:
        updateVulnerable(dt);
        break;
      case BossState.stunned:
        updateStunned(dt);
        break;
      case BossState.death:
        break;
    }
  }
  
  /// State değiştir
  void changeState(BossState newState) {
    if (currentState == newState) return;
    currentState = newState;
    stateTimer = 0;
    onStateChange(newState);
  }
  
  /// Hasar al - BOSS HER ZAMAN HASAR ALABİLİR
  void takeDamage(double damage) {
    if (isDead) return;
    
    currentHealth -= damage;
    _audioService.playEnemyHit();
    
    if (currentHealth <= 0) {
      currentHealth = 0;
      isDead = true;
      changeState(BossState.death);
      onDeath();
    } else {
      onDamageTaken(damage);
    }
  }
  
  /// Stun et
  void stun(double duration) {
    stunDuration = duration;
    changeState(BossState.stunned);
  }
  
  /// Vulnerable yap (saldırı sonrası)
  void makeVulnerable(double duration) {
    vulnerableDuration = duration;
    changeState(BossState.vulnerable);
  }
  
  // Override edilecek metodlar
  void updateIdle(double dt);
  void updateCharging(double dt);
  void updateAttacking(double dt);
  void updateVulnerable(double dt);
  void updateStunned(double dt);
  
  void onStateChange(BossState newState);
  void onDamageTaken(double damage);
  void onDeath();
  
  /// Saldırı pattern'ını başlat
  void startAttackPattern();
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Boss health bar (boss'un üzerinde)
    _renderHealthBar(canvas);
    
    // Boss ismi
    _renderBossName(canvas);
  }
  
  void _renderHealthBar(Canvas canvas) {
    final barWidth = size.x * 0.9;
    final barHeight = 12.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -30.0; // Boss'un üstünde
    
    // Arka plan
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.black.withOpacity(0.8),
    );
    
    // Health
    final healthPercent = (currentHealth / maxHealth).clamp(0.0, 1.0);
    Color healthColor = Colors.green;
    if (healthPercent < 0.3) {
      healthColor = Colors.red;
    } else if (healthPercent < 0.6) {
      healthColor = Colors.orange;
    }
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX + 2, barY + 2, (barWidth - 4) * healthPercent, barHeight - 4),
        const Radius.circular(4),
      ),
      Paint()..color = healthColor,
    );
    
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    // HP yazısı
    final hpText = '${currentHealth.toInt()} / ${maxHealth.toInt()}';
    final textPainter = TextPainter(
      text: TextSpan(
        text: hpText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(barX + (barWidth - textPainter.width) / 2, barY + 1),
    );
  }
  
  void _renderBossName(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '👑 $bossName',
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
            Shadow(color: Colors.orange, blurRadius: 8),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, -50),
    );
  }
}
