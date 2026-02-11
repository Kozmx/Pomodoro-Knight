import 'dart:ui';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:pomodoro_knight/game/components/weapon.dart';
import 'package:pomodoro_knight/game/components/arrow.dart';
import 'package:pomodoro_knight/game/components/game_effects.dart';
import 'package:pomodoro_knight/game/focus_game.dart';
import 'package:pomodoro_knight/game/components/level_manager.dart';
import 'package:pomodoro_knight/game/components/elevator.dart';
import 'package:pomodoro_knight/game/services/player_stats_service.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';
import 'package:pomodoro_knight/game/enemy/slime/slime.dart';
import 'package:pomodoro_knight/game/enemy/slime/bat.dart';
import 'package:pomodoro_knight/game/enemy/flower/flower.dart';

enum PlayerState {
  idle,
  walk,
  jump,
  attack1,
  attack2,
  walkAttack1,
  walkAttack2,
  hurt,
  death,
}

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameRef<FocusGame> {
  final JoystickComponent joystick;

  Vector2 velocity = Vector2.zero();
  final double speed = 300;
  final double gravity = 1000;
  final double jumpForce = 500;
  bool isGrounded = false;
  bool facingRight = true;

  double knockbackTimer = 0.0;

  // TEST: Klavye girişi için
  Vector2 testInput = Vector2.zero();

  // Character Selection
  int currentCharacter = 1; // 1 or 2

  // Health & Shield
  double get maxHealth => 100 + PlayerStatsService().maxHealthBonus;
  late double currentHealth;
  bool isShielding = false;

  // Animation Flags
  bool _isAttacking = false;
  bool _isHurt = false;
  bool _isDead = false;

  // Audio
  final GameAudioService _audioService = GameAudioService();
  bool _wasMoving = false;
  
  // Dash sistemi
  bool _isDashing = false;
  double _dashTimer = 0;
  final double _dashDuration = 0.2; // Biraz uzatıldı
  final double _dashSpeed = 800;
  Vector2 _dashDirection = Vector2.zero();
  
  /// Dodge kontrolü - boss projectile'ları geçer
  bool get isDodging => _isDashing;
  
  // Skill Buff sistemi
  double _skillBuffTimer = 0;
  double _attackSpeedBonus = 0;
  double _damageBonus = 0;
  double _healthRegen = 0;

  Player({required this.joystick})
    : super(size: Vector2(96, 96)); // Adjusted size

  @override
  Future<void> onLoad() async {
    print("Player: onLoad started");

    // Audio servisini başlat
    await _audioService.initialize();
    anchor = Anchor.center;

    // Hitbox - Adjusted for 96x96 sprite (scaled 1.5x from 64x64)
    // Original 64x64 had 24x48 hitbox at 20,16
    // New 96x96 should have 36x72 hitbox at 30,24
    add(RectangleHitbox(position: Vector2(30, 24), size: Vector2(36, 72)));

    await _loadCharacterAnimations();

    current = PlayerState.idle;

    // İlk health'i upgrade'lere göre ayarla
    currentHealth = maxHealth;

    // Health upgrade değişikliklerini dinle
    PlayerStatsService().onMaxHealthChanged = (oldMax, newMax) {
      // Eğer oyuncu ölmemişse ve mevcut can oranını koru
      if (!_isDead) {
        final oldTotal = 100 + oldMax;
        final newTotal = 100 + newMax;
        final healthRatio = currentHealth / oldTotal;
        currentHealth = (newTotal * healthRatio).clamp(1.0, newTotal);
      }
    };
  }

  Future<void> _loadCharacterAnimations() async {
    final images = Images(prefix: 'assets/');

    if (currentCharacter == 2) {
      // Player 2: Sprite sheet'ten satır bazlı yükle
      // 1. satır: idle, 2. satır: walk, 3. satır: run, 4. satır: attack, 5. satır: death, 6. satır: jump
      final sheet2Img = await images.load('player2/player2_sheet.png');
      print("Player 2 Sheet: ${sheet2Img.width}x${sheet2Img.height}");

      // Sheet: 1024x919, 6 sütun x 6 satır
      // Frame boyutu: yaklaşık 170x153 veya 171x153
      final sheet = SpriteSheet(
        image: sheet2Img,
        srcSize: Vector2(170.67, 153.17), // 1024/6 x 919/6
      );

      animations = {
        PlayerState.idle: sheet.createAnimation(row: 0, stepTime: 0.15, to: 6),
        PlayerState.walk: sheet.createAnimation(row: 1, stepTime: 0.1, to: 6),
        PlayerState.jump: sheet.createAnimation(row: 5, stepTime: 0.1, to: 6),
        PlayerState.attack1: sheet.createAnimation(
          row: 3,
          stepTime: 0.08,
          to: 4,
          loop: false,
        ),
        PlayerState.attack2: sheet.createAnimation(
          row: 3,
          stepTime: 0.08,
          to: 4,
          loop: false,
        ),
        PlayerState.walkAttack1: sheet.createAnimation(
          row: 3,
          stepTime: 0.08,
          to: 4,
          loop: false,
        ),
        PlayerState.walkAttack2: sheet.createAnimation(
          row: 3,
          stepTime: 0.08,
          to: 4,
          loop: false,
        ),
        PlayerState.hurt: sheet.createAnimation(
          row: 4,
          stepTime: 0.1,
          to: 3,
          loop: false,
        ),
        PlayerState.death: sheet.createAnimation(
          row: 4,
          stepTime: 0.15,
          to: 6,
          loop: false,
        ),
      };
    } else {
      // Player 1: Ayrı dosyalardan yükle
      final idleImg = await images.load('player/Idle.png');
      final walkImg = await images.load('player/Walk.png');
      final jumpImg = await images.load('player/Jump.png');
      final attack1Img = await images.load('player/Attack1.png');
      final attack2Img = await images.load('player/Attack2.png');
      final walkAttack1Img = await images.load('player/WalkAttack1.png');
      final walkAttack2Img = await images.load('player/WalkAttack2.png');
      final hurtImg = await images.load('player/Hurt.png');
      final deathImg = await images.load('player/Death.png');

      print("Player: Images loaded. Idle: ${idleImg.width}x${idleImg.height}");

      // Helper to create animation
      SpriteAnimation createAnim(
        Image image, {
        double stepTime = 0.1,
        bool loop = true,
      }) {
        final frameWidth = image.height.toDouble(); // Assume square frames
        final frameCount = (image.width / frameWidth).round();
        final sheet = SpriteSheet(
          image: image,
          srcSize: Vector2(frameWidth, frameWidth),
        );
        return sheet.createAnimation(
          row: 0,
          stepTime: stepTime,
          to: frameCount,
          loop: loop,
        );
      }

      animations = {
        PlayerState.idle: createAnim(idleImg),
        PlayerState.walk: createAnim(walkImg),
        PlayerState.jump: createAnim(jumpImg),
        PlayerState.attack1: createAnim(
          attack1Img,
          stepTime: 0.08,
          loop: false,
        ),
        PlayerState.attack2: createAnim(
          attack2Img,
          stepTime: 0.08,
          loop: false,
        ),
        PlayerState.walkAttack1: createAnim(
          walkAttack1Img,
          stepTime: 0.08,
          loop: false,
        ),
        PlayerState.walkAttack2: createAnim(
          walkAttack2Img,
          stepTime: 0.08,
          loop: false,
        ),
        PlayerState.hurt: createAnim(hurtImg, loop: false),
        PlayerState.death: createAnim(deathImg, loop: false),
      };
    }
  }

  Future<void> switchCharacter(int characterNumber) async {
    if (characterNumber == currentCharacter) return;

    currentCharacter = characterNumber;
    final previousState = current;
    await _loadCharacterAnimations();
    current = previousState; // Restore state after reload
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Shield visual
    if (isShielding) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        40,
        Paint()
          ..color = Colors.blue.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    
    // Buff aktifken parlama efekti
    if (hasActiveBuff) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        45,
        Paint()
          ..color = Colors.orange.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    
    // Dash efekti
    if (_isDashing) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        35,
        Paint()
          ..color = Colors.cyan.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  bool canMove = true;

  @override
  void update(double dt) {
    // Buff ve dash güncellemeleri
    _updateBuffs(dt);
    _updateDash(dt);
    
    // Dash sırasında normal fizik işleme
    if (_isDashing) {
      super.update(dt);
      return;
    }
    
    // Saldırı hızı upgrade'ine göre animasyon hızını artır
    final speedMultiplier = currentAttackSpeedMultiplier;
    final adjustedDt = _isAttacking ? dt * speedMultiplier : dt;
    super.update(adjustedDt);

    if (_isDead) {
      if (animationTicker?.done() == true) {
        // Maybe show Game Over screen here if not already handled
      }
      return;
    }

    // Handle One-Shot Animations
    if (_isHurt || _isAttacking) {
      if (animationTicker?.done() == true) {
        _isHurt = false;
        _isAttacking = false;
        current = PlayerState.idle;
      } else {
        // If attacking while moving (WalkAttack), allow movement?
        // The user said "hitting while running", so yes.
        // But if it's a standing attack, maybe stop?
        // For now, let's allow movement logic to run, but maybe reduced speed?
      }
    }

    if (knockbackTimer > 0) {
      knockbackTimer -= dt;
      velocity.x *= 0.9;
    } else if (canMove) {
      // Horizontal movement - joystick veya test input
      Vector2 input = joystick.relativeDelta;

      // TEST: Klavye girişi varsa onu kullan
      if (testInput.length > 0) {
        input = testInput;
      }

      if (input.x.abs() > 0.1 || joystick.direction != JoystickDirection.idle) {
        double currentSpeed = isShielding ? speed * 0.3 : speed;
        velocity.x = input.x * currentSpeed;

        if (velocity.x > 0) facingRight = true;
        if (velocity.x < 0) facingRight = false;
      } else {
        velocity.x = 0;
      }

      // Jump - joystick veya test input
      if ((joystick.relativeDelta.y < -0.5 || testInput.y < -0.5) &&
          isGrounded) {
        velocity.y = -jumpForce;
        isGrounded = false;
        _audioService.playJump(); // Zıplama sesi
      }
    } else {
      velocity.x = 0;
    }

    // Gravity
    velocity.y += gravity * dt;

    // Apply velocity
    position += velocity * dt;

    // Ground, Ramp & Platform collision
    double floorY = 800;

    // Rampa kontrolü
    final ramps = gameRef.world.children.whereType<Ramp>();
    for (final ramp in ramps) {
      final rampY = ramp.getYAtX(position.x);
      if (rampY != double.infinity && position.y + size.y / 2 >= rampY) {
        if (rampY < floorY) floorY = rampY;
      }
    }

    // Platform kontrolü - SADECE düşerken (velocity.y >= 0) ve üstten yaklaşırken
    final platforms = gameRef.world.children.whereType<Platform>();
    for (final platform in platforms) {
      final platformY = platform.getYAtX(position.x);
      if (platformY != double.infinity) {
        // Oyuncunun ayak pozisyonu
        final playerBottom = position.y + size.y / 2;
        final playerPrevBottom = playerBottom - velocity.y * dt;

        // Sadece düşerken (velocity.y >= 0) VE önceki frame'de platformun üstündeyse
        // veya şu an platformun üzerinde ve az üstündeyse
        if (velocity.y >= 0 &&
            playerPrevBottom <= platformY + 20 &&
            playerBottom >= platformY) {
          if (platformY < floorY) floorY = platformY;
        }
      }
    }

    if (position.y + size.y / 2 >= floorY) {
      position.y = floorY - size.y / 2;
      velocity.y = 0;
      isGrounded = true;
    }

    // World bounds
    if (gameRef.levelManager.state == LevelState.transitioning) {
      // Asansör transition - oyuncuyu asansör bölgesinde tut (sağ tarafta)
      final elevatorX = 2000 - 80; // Asansör pozisyonu
      if (position.x < elevatorX - 100) position.x = elevatorX - 100;
      if (position.x > elevatorX + 50) position.x = elevatorX + 50;
    } else {
      if (position.x < size.x / 2) position.x = size.x / 2;
      if (position.x > 2000 - size.x / 2) position.x = 2000 - size.x / 2;
    }

    // Footstep sesleri - yerde ve hareket ediyorsa
    final isMoving = velocity.x.abs() > 10 && isGrounded && !_isDead;
    if (isMoving) {
      _audioService.playFootstep(dt);
      _wasMoving = true;
    } else if (_wasMoving) {
      _audioService.resetFootstepCooldown();
      _wasMoving = false;
    }

    // Update Animation State
    _updateAnimationState();

    // Flip sprite based on direction
    if (facingRight) {
      scale.x = 1;
    } else {
      scale.x = -1;
    }
  }

  void _updateAnimationState() {
    if (_isDead) {
      current = PlayerState.death;
      return;
    }
    if (_isHurt) {
      current = PlayerState.hurt;
      return;
    }
    if (_isAttacking) {
      // Current attack state is already set in attack()
      return;
    }

    if (!isGrounded) {
      current = PlayerState.jump;
    } else if (velocity.x.abs() > 0.1) {
      current = PlayerState.walk;
    } else {
      current = PlayerState.idle;
    }
  }

  void setShield(bool active) {
    isShielding = active;
  }

  void takeDamage(double amount, Vector2 sourcePosition) {
    if (isShielding || _isDead) return; // Zaten ölüyse hasar alma

    currentHealth -= amount;
    _audioService.playPlayerHurt(); // Hasar sesi
    
    if (currentHealth <= 0 && !_isDead) { // Sadece ilk kez ölüyorsa
      currentHealth = 0;
      _isDead = true;
      current = PlayerState.death;
      animationTicker?.reset();
      _audioService.playPlayerDeath(); // Ölüm sesi
    } else if (!_isDead) {
      _isHurt = true;
      _isAttacking = false;
      current = PlayerState.hurt;
      animationTicker?.reset();
    }

    takeKnockback(sourcePosition);
  }

  void takeKnockback(Vector2 sourcePosition) {
    if (knockbackTimer > 0) return;

    Vector2 direction = (position - sourcePosition).normalized();
    if (direction.x.abs() < 0.5) {
      double sign = direction.x.sign;
      if (sign == 0) sign = 1;
      direction.x = sign * 0.5;
      direction.normalize();
    }

    if (isShielding) {
      velocity = Vector2(direction.x * 200, -60);
      knockbackTimer = 0.15;
    } else {
      velocity = Vector2(direction.x * 400, -120);
      knockbackTimer = 0.3;
    }
  }

  void attack() {
    if (_isDead || _isHurt || _isAttacking) return;

    _isAttacking = true;

    final statsService = PlayerStatsService();
    
    // Ranged mı melee mi kontrol et
    if (statsService.isRangedWeapon) {
      _performRangedAttack(statsService);
    } else {
      _performMeleeAttack(statsService);
    }
  }
  
  /// Yakın dövüş saldırısı (kılıç vb.)
  void _performMeleeAttack(PlayerStatsService statsService) {
    // Kılıç swoosh sesi çal
    _audioService.playSwordSwoosh();

    // Choose attack animation based on movement
    if (velocity.x.abs() > 0.1) {
      // Moving attack
      current = (DateTime.now().millisecond % 2 == 0)
          ? PlayerState.walkAttack1
          : PlayerState.walkAttack2;
    } else {
      // Standing attack
      current = (DateTime.now().millisecond % 2 == 0)
          ? PlayerState.attack1
          : PlayerState.attack2;
    }

    animationTicker?.reset();

    // Spawn weapon logic - boss savaşında daha büyük hitbox
    final isBossFight = gameRef.levelManager.isBossFloor;
    final weaponSize = isBossFight ? Vector2(80, 80) : Vector2(40, 40);
    final weaponPosition =
        position.clone() +
        Vector2(facingRight ? size.x / 2 : -size.x / 2 - weaponSize.x, -15);

    // Weapon artık kendi stats'larını PlayerStatsService'ten alıyor
    final weapon = Weapon(
      position: weaponPosition,
      size: weaponSize,
    );
    parent?.add(weapon);
  }
  
  /// Uzak menzilli saldırı (yay vb.)
  void _performRangedAttack(PlayerStatsService statsService) {
    // Ok sesi çal
    _audioService.playSwordSwoosh(); // TODO: Ok sesi eklenebilir
    
    // Attack animasyonu
    if (velocity.x.abs() > 0.1) {
      current = PlayerState.walkAttack1;
    } else {
      current = PlayerState.attack1;
    }
    animationTicker?.reset();
    
    // En yakın düşmanı bul ve hedef al
    final target = _findNearestEnemy();
    
    // Ok yönünü hesapla
    Vector2 arrowVelocity;
    if (target != null) {
      // Düşmana doğru nişan al
      final direction = (target - position).normalized();
      arrowVelocity = direction * statsService.projectileSpeed;
      
      // Yüzü düşmana dön
      if (direction.x > 0) {
        facingRight = true;
      } else if (direction.x < 0) {
        facingRight = false;
      }
    } else {
      // Düşman yoksa baktığı yöne ateş et
      arrowVelocity = Vector2(
        facingRight ? statsService.projectileSpeed : -statsService.projectileSpeed,
        0,
      );
    }
    
    // Crit kontrolü
    final Random random = Random();
    final isCritical = random.nextDouble() < statsService.totalCritChance;
    final damage = isCritical 
        ? statsService.totalBaseDamage * 2 
        : statsService.totalBaseDamage;
    
    // Ok rengi silaha göre
    Color arrowColor;
    final weaponId = statsService.equippedWeaponId ?? '';
    if (weaponId.contains('fire')) {
      arrowColor = Colors.deepOrange;
    } else if (weaponId.contains('ice')) {
      arrowColor = Colors.lightBlue;
    } else if (weaponId.contains('crossbow')) {
      arrowColor = Colors.amber;
    } else {
      arrowColor = Colors.brown;
    }
    
    // Pierce sayısı (crossbow için)
    int maxPierce = 0;
    if (statsService.weaponSpecialEffect.contains('Pierce')) {
      maxPierce = 2;
    }
    
    // Ok spawn pozisyonu
    final arrowPosition = position.clone() + 
        Vector2(facingRight ? 30 : -30, -10);
    
    final arrow = Arrow(
      position: arrowPosition,
      velocity: arrowVelocity,
      damage: damage,
      isCritical: isCritical,
      arrowColor: arrowColor,
      specialEffect: statsService.weaponSpecialEffect,
      maxPierce: maxPierce,
    );
    parent?.add(arrow);
  }
  
  /// En yakın düşmanı bul (otomatik hedefleme)
  Vector2? _findNearestEnemy() {
    double nearestDistance = double.infinity;
    Vector2? nearestPosition;
    
    // Maksimum hedefleme mesafesi
    const maxRange = 500.0;
    
    // Tüm düşmanları tara
    final parentComponent = parent;
    if (parentComponent == null) return null;
    
    for (final component in parentComponent.children) {
      Vector2? enemyPos;
      
      if (component is Enemy) {
        enemyPos = component.position;
      }
      if (component is FlyingEnemy) {
        enemyPos = component.position;
      }
      if (component is FlowerEnemy) {
        enemyPos = component.position;
      }
      
      if (enemyPos != null) {
        final distance = position.distanceTo(enemyPos);
        if (distance < nearestDistance && distance < maxRange) {
          nearestDistance = distance;
          nearestPosition = enemyPos.clone();
        }
      }
    }
    
    return nearestPosition;
  }

  /// Oyuncuyu yeniden canlandır - tüm state'leri sıfırla
  void respawn() {
    _isDead = false;
    _isHurt = false;
    _isAttacking = false;
    currentHealth = maxHealth;
    velocity = Vector2.zero();
    canMove = true;
    knockbackTimer = 0;
    isShielding = false;
    _isDashing = false;
    _skillBuffTimer = 0;
    _attackSpeedBonus = 0;
    _damageBonus = 0;
    _healthRegen = 0;
    current = PlayerState.idle;
    animationTicker?.reset();
  }
  
  /// Dash yeteneği
  void performDash() {
    if (_isDashing || _isDead || !canMove) return;
    
    _isDashing = true;
    _dashTimer = _dashDuration;
    
    // Yürüdüğümüz yöne dash at
    if (velocity.x.abs() > 10 || testInput.x.abs() > 0.1) {
      _dashDirection = Vector2(facingRight ? 1 : -1, 0);
    } else {
      // Duruyorsak baktığımız yöne
      _dashDirection = Vector2(facingRight ? 1 : -1, 0);
    }
  }
  
  /// Skill buff uygula
  void applySkillBuff({
    required double attackSpeedBonus,
    required double damageBonus,
    required double healthRegen,
    required double duration,
  }) {
    _skillBuffTimer = duration;
    _attackSpeedBonus = attackSpeedBonus;
    _damageBonus = damageBonus;
    _healthRegen = healthRegen;
  }
  
  // Can yenilenme görseli için
  double _healTextCooldown = 0;
  double _accumulatedHeal = 0;
  
  /// Aktif buff'ları güncelle (update içinde çağrılacak)
  void _updateBuffs(double dt) {
    if (_skillBuffTimer > 0) {
      _skillBuffTimer -= dt;
      
      // Can yenilenmesi
      if (_healthRegen > 0 && currentHealth < maxHealth) {
        final healAmount = _healthRegen * dt;
        currentHealth = (currentHealth + healAmount).clamp(0, maxHealth);
        
        // Heal text cooldown - her 0.5 saniyede bir göster
        _accumulatedHeal += healAmount;
        _healTextCooldown -= dt;
        
        if (_healTextCooldown <= 0 && _accumulatedHeal >= 1) {
          // +HP yazısı spawn et
          parent?.add(HealText(
            position: position.clone() + Vector2(0, -50),
            amount: _accumulatedHeal,
          ));
          
          // Heal sesi
          _audioService.playHeal();
          
          _accumulatedHeal = 0;
          _healTextCooldown = 0.5;
        }
      }
      
      if (_skillBuffTimer <= 0) {
        _attackSpeedBonus = 0;
        _damageBonus = 0;
        _healthRegen = 0;
      }
    }
  }
  
  /// Dash güncelle
  void _updateDash(double dt) {
    if (_isDashing) {
      _dashTimer -= dt;
      
      // Dash hareketi
      position += _dashDirection * _dashSpeed * dt;
      
      if (_dashTimer <= 0) {
        _isDashing = false;
      }
    }
  }
  
  // Getter'lar - weapon ve diğer sistemler için
  double get currentDamageMultiplier => PlayerStatsService().damageMultiplier * (1 + _damageBonus);
  double get currentAttackSpeedMultiplier => PlayerStatsService().attackSpeedMultiplier * (1 + _attackSpeedBonus);
  bool get hasActiveBuff => _skillBuffTimer > 0;
}
