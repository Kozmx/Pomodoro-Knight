import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/xp_effect.dart';
import 'package:pomodoro_knight/game/enemy/boss/boss_base.dart';
import 'package:pomodoro_knight/game/enemy/boss/boss_projectile.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';

/// İlk Boss - Slime King
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
  Color _bodyColor = const Color(0xFF4CAF50);
  final Color _crownColor = const Color(0xFFFFD700);
  double _glowIntensity = 0;
  double _damageFlash = 0;
  
  // Movement
  bool _facingRight = true;
  
  final Random _rnd = Random();

  SlimeKing({
    required super.player,
    required double level,
  }) : super(
    maxHealth: 200 + (level * 50),
    baseDamage: 15 + (level * 3),
    bossName: 'Slime King',
    size: Vector2(256, 256),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
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
    
    // Damage flash
    if (_damageFlash > 0) {
      _damageFlash -= dt * 5;
    }
  }
  
  void _updateAnimation(double dt) {
    _bounceOffset = sin(_animTime * 3) * 5;
    
    switch (currentState) {
      case BossState.idle:
        _stretchX = 1.0 + sin(_animTime * 2) * 0.05;
        _stretchY = 1.0 - sin(_animTime * 2) * 0.05;
        break;
      case BossState.charging:
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
        _stretchX = 1.0 + sin(_animTime * 20) * 0.05;
        _stretchY = 1.0 - sin(_animTime * 20) * 0.05;
        _glowIntensity = 0;
        break;
      case BossState.death:
        _stretchY = max(0.1, 1.0 - stateTimer * 0.5);
        _stretchX = min(2.0, 1.0 + stateTimer * 0.8);
        break;
    }
  }

  @override
  void updateIdle(double dt) {
    _facingRight = player.position.x > position.x;
    
    if (stateTimer > 2.0 && attackCooldown <= 0) {
      startAttackPattern();
    }
  }

  @override
  void updateCharging(double dt) {
    _facingRight = player.position.x > position.x;
    
    const chargeTime = 1.5;
    if (stateTimer >= chargeTime) {
      changeState(BossState.attacking);
      _launchAttack();
    }
  }

  @override
  void updateAttacking(double dt) {
    if (_projectilesThrown >= _projectilesInPattern) {
      makeVulnerable(2.5);
      return;
    }
    
    if (_attackDelay <= 0) {
      _throwProjectile();
      _attackDelay = 0.4;
    }
  }

  @override
  void updateVulnerable(double dt) {
    vulnerableDuration -= dt;
    
    if (vulnerableDuration <= 0) {
      attackCooldown = 1.5;
      changeState(BossState.idle);
    }
  }

  @override
  void updateStunned(double dt) {
    stunDuration -= dt;
    
    if (stunDuration <= 0) {
      attackCooldown = 2.0;
      changeState(BossState.idle);
    }
  }

  @override
  void startAttackPattern() {
    changeState(BossState.charging);
    _projectilesThrown = 0;
    
    attackPattern = _rnd.nextInt(3);
    switch (attackPattern) {
      case 0:
        _projectilesInPattern = 3;
        break;
      case 1:
        _projectilesInPattern = 5;
        break;
      case 2:
        _projectilesInPattern = 4;
        break;
    }
  }
  
  void _launchAttack() {
    GameAudioService().playEnemyHit();
  }
  
  void _throwProjectile() {
    _projectilesThrown++;
    
    final spawnPos = position.clone();
    spawnPos.y += size.y * 0.3;
    
    switch (attackPattern) {
      case 0:
        _spawnProjectileAtPlayer(spawnPos);
        break;
      case 1:
        _spawnFanProjectiles(spawnPos);
        break;
      case 2:
        _spawnRandomProjectile(spawnPos);
        break;
    }
  }
  
  void _spawnProjectileAtPlayer(Vector2 spawnPos) {
    final direction = (player.position - spawnPos).normalized();
    const speed = 300.0;
    
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
    
    const fanCount = 5;
    const spreadAngle = pi / 4;
    
    for (int i = 0; i < fanCount; i++) {
      final angle = baseAngle - spreadAngle / 2 + 
                    (spreadAngle / (fanCount - 1)) * i;
      
      final direction = Vector2(cos(angle), sin(angle));
      const speed = 350.0;
      
      final projectile = BossProjectile(
        position: spawnPos.clone(),
        velocity: direction * speed,
        damage: baseDamage * 0.8,
        color: _bodyColor.withOpacity(0.8),
        projectileSize: 20,
      );
      parent?.add(projectile);
    }
    
    _projectilesThrown = _projectilesInPattern;
  }
  
  void _spawnRandomProjectile(Vector2 spawnPos) {
    final angle = _rnd.nextDouble() * pi * 2;
    final direction = Vector2(cos(angle), sin(angle));
    direction.y = direction.y.abs();
    direction.normalize();
    
    final speed = 250.0 + _rnd.nextDouble() * 150;
    
    final projectile = BossProjectile(
      position: spawnPos,
      velocity: direction * speed,
      damage: baseDamage * 0.6,
      color: _bodyColor.withOpacity(0.7),
      projectileSize: 16 + _rnd.nextInt(12).toDouble(),
    );
    parent?.add(projectile);
  }

  @override
  void onStateChange(BossState newState) {
    switch (newState) {
      case BossState.vulnerable:
        _glowIntensity = 1.0;
        break;
      case BossState.stunned:
        _bodyColor = const Color(0xFF9E9E9E);
        break;
      default:
        _bodyColor = const Color(0xFF4CAF50);
        break;
    }
  }

  @override
  void onDamageTaken(double damage) {
    _damageFlash = 1.0;
    _glowIntensity = 1.0;
  }

  @override
  void onDeath() {
    gameRef.levelManager.onBossKilled();
    GameAudioService().playSlimeDeath();
    
    spawnXpEffect(
      gameRef: gameRef,
      position: position.clone(),
      xpAmount: 50,
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      removeFromParent();
    });
  }

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
    
    // Hasar flash
    if (_damageFlash > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2 + _bounceOffset),
          width: size.x * 0.85 * _stretchX,
          height: size.y * 0.75 * _stretchY,
        ),
        Paint()
          ..color = Colors.white.withOpacity(_damageFlash * 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    
    // Ana gövde
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
      Paint()..color = _damageFlash > 0 
          ? Color.lerp(_bodyColor, Colors.white, _damageFlash)!
          : _bodyColor,
    );
    
    // Parlaklık
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
    
    // Health bar ve isim (base class)
    super.render(canvas);
  }
  
  void _drawCrown(Canvas canvas) {
    final crownY = size.y * 0.15 + _bounceOffset;
    final crownWidth = size.x * 0.4;
    const crownHeight = 40.0;
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
    const eyeSize = 20.0;
    
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
    
    // Kızgın kaş
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
}
