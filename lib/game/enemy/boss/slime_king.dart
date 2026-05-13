import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/xp_effect.dart';
import 'package:pomodoro_knight/game/enemy/boss/boss_base.dart';
import 'package:pomodoro_knight/game/enemy/boss/boss_projectile.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';

/// İlk Boss - Slime King
class SlimeKing extends BossBase {
  // Attack patterns
  int _projectilesThrown = 0;
  int _projectilesInPattern = 0;
  double _attackDelay = 0;
  
  // Visual
  Color _bodyColor = Colors.grey;
  
  // Movement
  bool _facingRight = true;
  
  final Random _rnd = Random();

  SlimeKing({
    required super.player,
    required double level,
  }) : super(
    maxHealth: 200 + (level * 50),
    baseDamage: 15 + (level * 3),
    bossName: 'Skeleton Boss',
    size: Vector2(256, 256),
  );

  late final SpriteAnimationGroupComponent<BossState> animationComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load images
    final attackImg = await Flame.images.load('skeletonboss/skeletonATTACK.PNG');
    final deathImg = await Flame.images.load('skeletonboss/skeletonDEATH.PNG');
    final walkImg = await Flame.images.load('skeletonboss/skeletonWALK.PNG');

    SpriteAnimation createAnim(ui.Image img, {bool loop = true, double stepTime = 0.15}) {
      final frameHeight = img.height.toDouble();
      final frameCount = (img.width / img.height).round();
      return SpriteAnimation.fromFrameData(
        img,
        SpriteAnimationData.sequenced(
          amount: frameCount,
          stepTime: stepTime,
          textureSize: Vector2(frameHeight, frameHeight),
          loop: loop,
        ),
      );
    }

    animationComponent = SpriteAnimationGroupComponent<BossState>(
      animations: {
        BossState.idle: createAnim(walkImg),
        BossState.charging: createAnim(walkImg),
        BossState.attacking: createAnim(attackImg, loop: false, stepTime: 0.1),
        BossState.vulnerable: createAnim(walkImg),
        BossState.stunned: createAnim(walkImg),
        BossState.death: createAnim(deathImg, loop: false, stepTime: 0.15),
      },
      current: BossState.idle,
      size: size,
    );
    
    add(animationComponent);
    
    changeState(BossState.idle);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isDead) {
      animationComponent.current = BossState.death;
      return;
    }
    
    // Update animation state to match BossState
    animationComponent.current = currentState;
    
    // Cooldown timer
    if (attackCooldown > 0) {
      attackCooldown -= dt;
    }
    
    // Attack delay
    if (_attackDelay > 0) {
      _attackDelay -= dt;
    }
    
    // Flip sprite based on direction
    if (_facingRight && animationComponent.scale.x < 0) {
      animationComponent.flipHorizontally();
    } else if (!_facingRight && animationComponent.scale.x > 0) {
      animationComponent.flipHorizontally();
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
        color: _bodyColor.withValues(alpha: 0.8),
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
      color: _bodyColor.withValues(alpha: 0.7),
      projectileSize: 16 + _rnd.nextInt(12).toDouble(),
    );
    parent?.add(projectile);
  }

  @override
  void onStateChange(BossState newState) {
    switch (newState) {
      case BossState.vulnerable:
        break;
      case BossState.stunned:
        _bodyColor = Colors.grey.shade400;
        break;
      default:
        _bodyColor = Colors.grey;
        break;
    }
  }

  @override
  void onDamageTaken(double damage) {
    // Görsel efektler kaldırıldı
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
    // Health bar ve isim (base class)
    super.render(canvas);
  }
}
