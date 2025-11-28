import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/weapon.dart';

class Player extends PositionComponent with HasGameRef {
  static final _paint = Paint()..color = Colors.white;
  final JoystickComponent joystick;

  Vector2 velocity = Vector2.zero();
  final double speed = 300;
  final double gravity = 1000;
  final double jumpForce = 500;
  bool isGrounded = false;
  bool facingRight = true;
  
  double knockbackTimer = 0.0;
  
  // Health & Shield
  double maxHealth = 100;
  double currentHealth = 100;
  bool isShielding = false;

  Player({required this.joystick});

  @override
  Future<void> onLoad() async {
    size = Vector2(50, 50);
    anchor = Anchor.center;
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // Shield visual
    if (isShielding) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2), 
        40, 
        Paint()..color = Colors.blue.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 3
      );
    }
    
    canvas.drawRect(size.toRect(), _paint);
    
    // Eyes to show direction
    final eyeOffset = facingRight ? 10.0 : -10.0;
    canvas.drawCircle(Offset(size.x / 2 + eyeOffset, size.y / 3), 4, Paint()..color = Colors.black);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (knockbackTimer > 0) {
      knockbackTimer -= dt;
      // Apply friction while knocked back
      velocity.x *= 0.9; 
    } else {
      // Horizontal movement
      if (joystick.direction != JoystickDirection.idle) {
        // Reduce speed if shielding
        double currentSpeed = isShielding ? speed * 0.3 : speed;
        velocity.x = joystick.relativeDelta.x * currentSpeed;
        
        if (velocity.x > 0) facingRight = true;
        if (velocity.x < 0) facingRight = false;
      } else {
        velocity.x = 0;
      }

      // Jump (Up direction)
      if (joystick.relativeDelta.y < -0.5 && isGrounded) {
        velocity.y = -jumpForce;
        isGrounded = false;
      }
    }

    // Gravity
    velocity.y += gravity * dt;

    // Apply velocity
    position += velocity * dt;

    // Ground collision
    // Zemin seviyesi artık dünya koordinatlarına göre sabit (Background'da çizdiğimiz zemin 800'de başlıyor)
    double floorY = 800; 
    if (position.y + size.y / 2 >= floorY) {
      position.y = floorY - size.y / 2;
      velocity.y = 0;
      isGrounded = true;
    }
    
    // World bounds (Sol ve Sağ sınırlar)
    if (position.x < size.x / 2) {
      position.x = size.x / 2;
    }
    if (position.x > 2000 - size.x / 2) { // 2000 background genişliği
      position.x = 2000 - size.x / 2;
    }
  }

  void setShield(bool active) {
    isShielding = active;
  }

  void takeDamage(double amount, Vector2 sourcePosition) {
    if (isShielding) {
      // Block damage, maybe slight pushback?
      return;
    }

    currentHealth -= amount;
    if (currentHealth <= 0) {
      currentHealth = 0;
      // Game Over logic handled in FocusGame update or via callback
    }
    
    takeKnockback(sourcePosition);
  }

  void takeKnockback(Vector2 sourcePosition) {
    if (knockbackTimer > 0) return;

    Vector2 direction = (position - sourcePosition).normalized();
    
    if (isShielding) {
      // Reduced knockback when shielding
      velocity = Vector2(direction.x * 200, -100);
      knockbackTimer = 0.15;
    } else {
      // Normal knockback up and away
      velocity = Vector2(direction.x * 400, -200);
      knockbackTimer = 0.3; // Disable controls briefly
    }
  }

  void attack() {
    // Spawn weapon in front of player
    final weaponSize = Vector2(40, 40);
    // Adjusted Y offset to -15 to move it up
    final weaponPosition = position.clone() + Vector2(facingRight ? size.x / 2 : -size.x / 2 - weaponSize.x, -15);
    
    final weapon = Weapon(position: weaponPosition, size: weaponSize);
    parent?.add(weapon);
  }
}
