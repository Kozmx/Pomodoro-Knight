import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:pomodoro_knight/game/components/weapon.dart';
import 'package:pomodoro_knight/game/focus_game.dart';
import 'package:pomodoro_knight/game/components/level_manager.dart';
import 'package:pomodoro_knight/game/components/elevator.dart';

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

  // Health & Shield
  double maxHealth = 100;
  double currentHealth = 100;
  bool isShielding = false;

  // Animation Flags
  bool _isAttacking = false;
  bool _isHurt = false;
  bool _isDead = false;

  Player({required this.joystick})
    : super(size: Vector2(96, 96)); // Adjusted size

  @override
  Future<void> onLoad() async {
    print("Player: onLoad started");
    anchor = Anchor.center;

    // Hitbox - Adjusted for 96x96 sprite (scaled 1.5x from 64x64)
    // Original 64x64 had 24x48 hitbox at 20,16
    // New 96x96 should have 36x72 hitbox at 30,24
    add(RectangleHitbox(position: Vector2(30, 24), size: Vector2(36, 72)));

    final images = Images(prefix: 'assets/');

    // Load Images
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
      PlayerState.attack1: createAnim(attack1Img, stepTime: 0.08, loop: false),
      PlayerState.attack2: createAnim(attack2Img, stepTime: 0.08, loop: false),
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

    current = PlayerState.idle;
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
  }

  bool canMove = true;

  @override
  void update(double dt) {
    super.update(dt);

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
      if ((joystick.relativeDelta.y < -0.5 || testInput.y < -0.5) && isGrounded) {
        velocity.y = -jumpForce;
        isGrounded = false;
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
        if (velocity.y >= 0 && playerPrevBottom <= platformY + 20 && playerBottom >= platformY) {
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
    if (isShielding) return;

    currentHealth -= amount;
    if (currentHealth <= 0) {
      currentHealth = 0;
      _isDead = true;
      current = PlayerState.death;
      animationTicker?.reset();
    } else {
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

    // Choose attack animation based on movement
    if (velocity.x.abs() > 0.1) {
      // Moving attack
      // Randomly choose between WalkAttack1 and WalkAttack2
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

    // Spawn weapon logic (keep existing)
    final weaponSize = Vector2(40, 40);
    final weaponPosition =
        position.clone() +
        Vector2(facingRight ? size.x / 2 : -size.x / 2 - weaponSize.x, -15);

    final weapon = Weapon(position: weaponPosition, size: weaponSize);
    parent?.add(weapon);
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
    current = PlayerState.idle;
    animationTicker?.reset();
  }
}
