import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/xp_effect.dart';
import 'package:pomodoro_knight/game/enemy/boss/boss_base.dart';
import 'package:pomodoro_knight/game/enemy/boss/boss_projectile.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';

/// İlk Boss - Slime King
/// Dev bir slime, farklı saldırı kalıplarına sahip
class SlimeKing extends BossBase {
  // Animation
  double _animTime = 0;
  double _bounceOffset = 0;
  double _stretchX = 1.0;
  double _stretchY = 1.0;
  
  // Attack patterns
  int _projectilesThrown = 0;
  int _projectilesInPattern = 0;
  double _attackDelay = 0;
  
  // Visual
  Color _bodyColor = const Color(0xFF4CAF50); // Yeşil slime
  Color _crownColor = const Color(0xFFFFD700); // Altın taç
  double _glowIntensity = 0;
  
  // Movement
  bool _facingRight = true;
  
  final Random _rnd = Random();

  SlimeKing({
    required super.player,
    required double level,
  }) : super(
    maxHealth: 200 + (level * 50), // Level'e göre HP artar
    baseDamage: 15 + (level * 3),
    bossName: 'Slime King',
    size: Vector2(256, 256), // Büyük boss
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Boss başlangıçta idle
    changeState(BossState.idle);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isDead) return;
    
    _animTime += dt;
    _updateAnimation(dt);
    
    // Cooldown timer
    if (attackCooldown > 0) {
      attackCooldown -= dt;
    }
    
    // Attack delay
    if (_attackDelay > 0) {
      _attackDelay -= dt;
    }
  }
  
  void _updateAnimation(double dt) {
    // Temel bounce animasyonu
    _bounceOffset = sin(_animTime * 3) * 5;
    
    // State'e göre stretch
    switch (currentState) {
      case BossState.idle:
        _stretchX = 1.0 + sin(_animTime * 2) * 0.05;
        _stretchY = 1.0 - sin(_animTime * 2) * 0.05;
        break;
      case BossState.charging:
        // Sıkışma efekti
        _stretchX = 1.0 + min(stateTimer * 0.5, 0.3);
        _stretchY = 1.0 - min(stateTimer * 0.3, 0.2);
        _glowIntensity = min(stateTimer * 0.5, 1.0);
        break;
      case BossState.attacking:
        _stretchX = 0.8;
        _stretchY = 1.3;
        break;
      case BossState.vulnerable:
        _stretchX = 1.1;
        _stretchY = 0.9;
        _glowIntensity = 0.5 + sin(_animTime * 5) * 0.3;
        break;
      case BossState.stunned:
        // Titreme
        _stretchX = 1.0 + sin(_animTime * 20) * 0.05;
        _stretchY = 1.0 - sin(_animTime * 20) * 0.05;
        _glowIntensity = 0;
        break;
      case BossState.enraged:
        _stretchX = 1.0 + sin(_animTime * 4) * 0.1;
        _stretchY = 1.0 - sin(_animTime * 4) * 0.1;
        _bodyColor = Color.lerp(
          const Color(0xFF4CAF50),
          const Color(0xFFFF5722),
          0.5 + sin(_animTime * 3) * 0.5,
        )!;
        break;
      case BossState.death:
        _stretchY = max(0.1, 1.0 - stateTimer * 0.5);
        _stretchX = min(2.0, 1.0 + stateTimer * 0.8);
        break;
    }
  }

  // ==== STATE UPDATES ====
  
  @override
  void updateIdle(double dt) {
    // Oyuncuya bak
    _facingRight = player.position.x > position.x;
    
    // Kısa beklemeden sonra saldırıya geç
    if (stateTimer > 2.0 && attackCooldown <= 0) {
      startAttackPattern();
    }
  }

  @override
  void updateCharging(double dt) {
    // Oyuncuya doğru bak
    _facingRight = player.position.x > position.x;
    
    // Charge süresi sona erdi - saldır
    final chargeTime = attackPhase == BossAttackPhase.phase1 ? 1.5 : 
                       attackPhase == BossAttackPhase.phase2 ? 1.0 : 0.7;
    
    if (stateTimer >= chargeTime) {
      changeState(BossState.attacking);
      _launchAttack();
    }
  }

  @override
  void updateAttacking(double dt) {
    // Saldırı pattern'ı devam ediyor mu?
    if (_projectilesThrown >= _projectilesInPattern) {
      // Pattern bitti - vulnerable ol
      makeVulnerable(2.5);
      return;
    }
    
    // Sonraki projectile'ı fırlat
    if (_attackDelay <= 0) {
      _throwProjectile();
      _attackDelay = attackPhase == BossAttackPhase.phase1 ? 0.4 : 
                     attackPhase == BossAttackPhase.phase2 ? 0.25 : 0.15;
    }
  }

  @override
  void updateVulnerable(double dt) {
    vulnerableDuration -= dt;
    
    if (vulnerableDuration <= 0) {
      isVulnerable = false;
      attackCooldown = 1.5;
      changeState(BossState.idle);
    }
  }

  @override
  void updateStunned(double dt) {
    stunDuration -= dt;
    
    if (stunDuration <= 0) {
      isVulnerable = false;
      attackCooldown = 2.0;
      changeState(BossState.idle);
    }
  }

  @override
  void updateEnraged(double dt) {
    // Enraged modunda daha hızlı saldırı
    updateIdle(dt);
  }

  // ==== ATTACK LOGIC ====
  
  @override
  void startAttackPattern() {
    changeState(BossState.charging);
    _projectilesThrown = 0;
    
    // Pattern'a göre projectile sayısı
    attackPattern = _rnd.nextInt(3);
    switch (attackPattern) {
      case 0: // Tek yön
        _projectilesInPattern = attackPhase == BossAttackPhase.phase1 ? 3 : 
                                attackPhase == BossAttackPhase.phase2 ? 5 : 7;
        break;
      case 1: // Yelpaze
        _projectilesInPattern = attackPhase == BossAttackPhase.phase1 ? 3 : 5;
        break;
      case 2: // Rastgele dağılım
        _projectilesInPattern = attackPhase == BossAttackPhase.phase1 ? 4 : 
                                attackPhase == BossAttackPhase.phase2 ? 6 : 8;
        break;
    }
  }
  
  void _launchAttack() {
    // Saldırı başlangıç sesi (placeholder)
    GameAudioService().playEnemyHit();
  }
  
  void _throwProjectile() {
    _projectilesThrown++;
    
    final spawnPos = position.clone();
    spawnPos.y += size.y * 0.3;
    
    switch (attackPattern) {
      case 0: // Oyuncuya doğru tek yön
        _spawnProjectileAtPlayer(spawnPos);
        break;
      case 1: // Yelpaze
        _spawnFanProjectiles(spawnPos);
        break;
      case 2: // Rastgele
        _spawnRandomProjectile(spawnPos);
        break;
    }
  }
  
  void _spawnProjectileAtPlayer(Vector2 spawnPos) {
    final direction = (player.position - spawnPos).normalized();
    final speed = attackPhase == BossAttackPhase.phase1 ? 300.0 : 
                  attackPhase == BossAttackPhase.phase2 ? 400.0 : 500.0;
    
    final projectile = BossProjectile(
      position: spawnPos,
      velocity: direction * speed,
      damage: baseDamage,
      color: _bodyColor,
    );
    parent?.add(projectile);
  }
  
  void _spawnFanProjectiles(Vector2 spawnPos) {
    final baseAngle = atan2(
      player.position.y - spawnPos.y,
      player.position.x - spawnPos.x,
    );
    
    final fanCount = _projectilesInPattern;
    final spreadAngle = pi / 4; // 45 derece toplam yayılım
    
    for (int i = 0; i < fanCount; i++) {
      final angle = baseAngle - spreadAngle / 2 + 
                    (spreadAngle / (fanCount - 1)) * i;
      
      final direction = Vector2(cos(angle), sin(angle));
      final speed = 350.0;
      
      final projectile = BossProjectile(
        position: spawnPos.clone(),
        velocity: direction * speed,
        damage: baseDamage * 0.8,
        color: _bodyColor.withOpacity(0.8),
        size: 20,
      );
      parent?.add(projectile);
    }
    
    // Hepsini tek seferde attık
    _projectilesThrown = _projectilesInPattern;
  }
  
  void _spawnRandomProjectile(Vector2 spawnPos) {
    final angle = _rnd.nextDouble() * pi * 2;
    final direction = Vector2(cos(angle), sin(angle));
    
    // Aşağı doğru bias (oyuncuya doğru)
    direction.y = direction.y.abs();
    direction.normalize();
    
    final speed = 250.0 + _rnd.nextDouble() * 150;
    
    final projectile = BossProjectile(
      position: spawnPos,
      velocity: direction * speed,
      damage: baseDamage * 0.6,
      color: _bodyColor.withOpacity(0.7),
      size: 16 + _rnd.nextInt(12).toDouble(),
    );
    parent?.add(projectile);
  }

  // ==== CALLBACKS ====
  
  @override
  void onStateChange(BossState newState) {
    // State değişim efektleri
    switch (newState) {
      case BossState.vulnerable:
        _glowIntensity = 1.0;
        break;
      case BossState.stunned:
        _bodyColor = const Color(0xFF9E9E9E); // Gri
        break;
      default:
        _bodyColor = const Color(0xFF4CAF50);
        break;
    }
  }

  @override
  void onPhaseChange(BossAttackPhase newPhase) {
    // Phase geçişinde efekt
    if (newPhase == BossAttackPhase.phase2) {
      // Öfkeleniyor
      stun(1.0); // Kısa duraklama
    } else if (newPhase == BossAttackPhase.phase3) {
      // Desperasyon
      _bodyColor = const Color(0xFFFF5722); // Turuncu
      changeState(BossState.enraged);
    }
  }

  @override
  void onDamageTaken(double damage) {
    // Hasar efekti
    _glowIntensity = 1.0;
    // Boss health bar'ı güncelle
    gameRef.levelManager.updateBossHealth(currentHealth);
  }

  @override
  void onBlockedDamage() {
    // Kalkan efekti (placeholder - yanıp sönen)
    _glowIntensity = 0.5;
  }

  @override
  void onDeath() {
    gameRef.levelManager.onBossKilled();
    GameAudioService().playSlimeDeath();
    
    // Büyük XP ödülü
    spawnXpEffect(
      gameRef: gameRef,
      position: position.clone(),
      xpAmount: 50,
    );
    
    // Ölüm animasyonu bittikten sonra kaldır
    Future.delayed(const Duration(seconds: 2), () {
      removeFromParent();
    });
  }

  // ==== RENDER ====
  
  @override
  void render(Canvas canvas) {
    // Gölge
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y - 20),
        width: size.x * 0.7 * _stretchX,
        height: 30,
      ),
      Paint()..color = Colors.black.withOpacity(0.3),
    );
    
    // Ana gövde (slime)
    final bodyRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2 + _bounceOffset),
      width: size.x * 0.8 * _stretchX,
      height: size.y * 0.7 * _stretchY,
    );
    
    // Glow efekti
    if (_glowIntensity > 0) {
      canvas.drawOval(
        bodyRect.inflate(10),
        Paint()
          ..color = Colors.green.withOpacity(_glowIntensity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );
    }
    
    // Gövde
    canvas.drawOval(
      bodyRect,
      Paint()..color = _bodyColor,
    );
    
    // Parlaklık (highlight)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2 - 20, size.y / 2 - 30 + _bounceOffset),
        width: size.x * 0.3,
        height: size.y * 0.25,
      ),
      Paint()..color = Colors.white.withOpacity(0.3),
    );
    
    // Taç
    _drawCrown(canvas);
    
    // Gözler
    _drawEyes(canvas);
    
    // Vulnerable göstergesi
    if (isVulnerable) {
      _drawVulnerableIndicator(canvas);
    }
    
    // Health bar (base class'tan)
    super.render(canvas);
  }
  
  void _drawCrown(Canvas canvas) {
    final crownY = size.y * 0.15 + _bounceOffset;
    final crownWidth = size.x * 0.4;
    final crownHeight = 40.0;
    final crownX = size.x / 2;
    
    final path = Path()
      ..moveTo(crownX - crownWidth / 2, crownY + crownHeight)
      ..lineTo(crownX - crownWidth / 2, crownY + crownHeight * 0.3)
      ..lineTo(crownX - crownWidth / 4, crownY + crownHeight * 0.5)
      ..lineTo(crownX - crownWidth / 8, crownY)
      ..lineTo(crownX, crownY + crownHeight * 0.4)
      ..lineTo(crownX + crownWidth / 8, crownY)
      ..lineTo(crownX + crownWidth / 4, crownY + crownHeight * 0.5)
      ..lineTo(crownX + crownWidth / 2, crownY + crownHeight * 0.3)
      ..lineTo(crownX + crownWidth / 2, crownY + crownHeight)
      ..close();
    
    canvas.drawPath(path, Paint()..color = _crownColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.orange.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    // Mücevherler
    canvas.drawCircle(
      Offset(crownX - crownWidth / 8, crownY + 8),
      5,
      Paint()..color = Colors.red,
    );
    canvas.drawCircle(
      Offset(crownX + crownWidth / 8, crownY + 8),
      5,
      Paint()..color = Colors.blue,
    );
  }
  
  void _drawEyes(Canvas canvas) {
    final eyeY = size.y * 0.4 + _bounceOffset;
    final eyeOffsetX = size.x * 0.12;
    final eyeSize = 20.0;
    
    // Sol göz
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2 - eyeOffsetX, eyeY),
        width: eyeSize,
        height: eyeSize * 1.3,
      ),
      Paint()..color = Colors.white,
    );
    
    // Sol göz bebeği
    final pupilOffset = _facingRight ? 3.0 : -3.0;
    canvas.drawCircle(
      Offset(size.x / 2 - eyeOffsetX + pupilOffset, eyeY + 2),
      6,
      Paint()..color = Colors.black,
    );
    
    // Sağ göz
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2 + eyeOffsetX, eyeY),
        width: eyeSize,
        height: eyeSize * 1.3,
      ),
      Paint()..color = Colors.white,
    );
    
    // Sağ göz bebeği
    canvas.drawCircle(
      Offset(size.x / 2 + eyeOffsetX + pupilOffset, eyeY + 2),
      6,
      Paint()..color = Colors.black,
    );
    
    // Kızgın kaş (stunned değilse)
    if (currentState != BossState.stunned && currentState != BossState.vulnerable) {
      final browPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(size.x / 2 - eyeOffsetX - 12, eyeY - 18),
        Offset(size.x / 2 - eyeOffsetX + 8, eyeY - 12),
        browPaint,
      );
      canvas.drawLine(
        Offset(size.x / 2 + eyeOffsetX + 12, eyeY - 18),
        Offset(size.x / 2 + eyeOffsetX - 8, eyeY - 12),
        browPaint,
      );
    }
  }
  
  void _drawVulnerableIndicator(Canvas canvas) {
    // "ATTACK!" yazısı
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ATTACK!',
        style: TextStyle(
          color: Colors.yellow,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.x / 2 - textPainter.width / 2, -45),
    );
  }
}
