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
  enraged,       // Öfkeli mod (düşük HP)
  death,         // Ölüyor
}

/// Boss saldırı fazı
enum BossAttackPhase {
  phase1,  // Normal saldırılar
  phase2,  // Rage modu - daha hızlı saldırılar
  phase3,  // Desperate - yeni saldırı kalıpları
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
  BossAttackPhase attackPhase = BossAttackPhase.phase1;
  
  // Timing
  double stateTimer = 0;
  double attackCooldown = 0;
  double stunDuration = 0;
  double vulnerableDuration = 0;
  
  // Flags
  bool isDead = false;
  bool isVulnerable = false;
  int attackPattern = 0;
  int attacksInPattern = 0;
  
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
    // Hitbox ekle - Boss için daha büyük
    add(RectangleHitbox(
      position: Vector2(size.x * 0.2, size.y * 0.2),
      size: Vector2(size.x * 0.6, size.y * 0.6),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isDead) return;
    
    stateTimer += dt;
    
    // Phase kontrolü
    _updateAttackPhase();
    
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
      case BossState.enraged:
        updateEnraged(dt);
        break;
      case BossState.death:
        break;
    }
  }
  
  void _updateAttackPhase() {
    final healthPercent = currentHealth / maxHealth;
    if (healthPercent <= 0.3 && attackPhase != BossAttackPhase.phase3) {
      attackPhase = BossAttackPhase.phase3;
      onPhaseChange(BossAttackPhase.phase3);
    } else if (healthPercent <= 0.6 && attackPhase == BossAttackPhase.phase1) {
      attackPhase = BossAttackPhase.phase2;
      onPhaseChange(BossAttackPhase.phase2);
    }
  }
  
  /// State değiştir
  void changeState(BossState newState) {
    if (currentState == newState) return;
    currentState = newState;
    stateTimer = 0;
    onStateChange(newState);
  }
  
  /// Hasar al
  void takeDamage(double damage) {
    if (isDead) return;
    
    // Sadece vulnerable veya stunned iken hasar alabilir
    if (!isVulnerable && currentState != BossState.stunned && currentState != BossState.vulnerable) {
      // Hasar alamaz - kalkan efekti göster
      onBlockedDamage();
      return;
    }
    
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
    isVulnerable = true;
    changeState(BossState.stunned);
  }
  
  /// Vulnerable yap (saldırı sonrası)
  void makeVulnerable(double duration) {
    vulnerableDuration = duration;
    isVulnerable = true;
    changeState(BossState.vulnerable);
  }
  
  // Override edilecek metodlar
  void updateIdle(double dt);
  void updateCharging(double dt);
  void updateAttacking(double dt);
  void updateVulnerable(double dt);
  void updateStunned(double dt);
  void updateEnraged(double dt);
  
  void onStateChange(BossState newState);
  void onPhaseChange(BossAttackPhase newPhase);
  void onDamageTaken(double damage);
  void onBlockedDamage();
  void onDeath();
  
  /// Saldırı pattern'ını başlat
  void startAttackPattern();
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Boss health bar (büyük)
    _renderHealthBar(canvas);
    
    // State indicator (debug)
    _renderStateIndicator(canvas);
  }
  
  void _renderHealthBar(Canvas canvas) {
    final barWidth = size.x * 0.8;
    final barHeight = 10.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -25.0;
    
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.black.withOpacity(0.7),
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
        const Radius.circular(3),
      ),
      Paint()..color = healthColor,
    );
    
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(5),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
  
  void _renderStateIndicator(Canvas canvas) {
    // Vulnerable iken yeşil parlama
    if (isVulnerable) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x * 0.6,
        Paint()
          ..color = Colors.green.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    
    // Stunned iken yıldızlar (placeholder)
    if (currentState == BossState.stunned) {
      canvas.drawCircle(
        Offset(size.x / 2, -15),
        8,
        Paint()..color = Colors.yellow,
      );
    }
  }
}
