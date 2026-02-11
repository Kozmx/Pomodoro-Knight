import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

/// Boss tarafından fırlatılan projectile
/// Oyuncunun dodge etmesi gereken saldırı
class BossProjectile extends PositionComponent
    with CollisionCallbacks, HasGameRef<FocusGame> {
  final Vector2 velocity;
  final double damage;
  final Color color;
  
  double lifeTime = 0;
  double _animTime = 0;
  bool _hasHit = false;
  
  // Trail efekti için pozisyon geçmişi
  final List<Vector2> _trail = [];
  static const int _maxTrailLength = 8;

  BossProjectile({
    required Vector2 position,
    required this.velocity,
    required this.damage,
    this.color = const Color(0xFF4CAF50),
    double size = 24,
  }) : super(position: position, size: Vector2.all(size)) {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    // Hitbox - düşmanı dodge etmek için biraz daha küçük
    add(CircleHitbox(
      radius: size.x * 0.4,
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    _animTime += dt;
    lifeTime += dt;
    
    // Pozisyon güncelle
    position += velocity * dt;
    
    // Trail güncelle
    _trail.insert(0, position.clone());
    if (_trail.length > _maxTrailLength) {
      _trail.removeLast();
    }
    
    // Süre aşımı
    if (lifeTime > 5.0) {
      removeFromParent();
    }
    
    // Ekran dışı kontrolü
    if (position.x < -100 || position.x > 2200 || 
        position.y < -100 || position.y > 1000) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (_hasHit) return;
    
    if (other is Player) {
      // Oyuncu dodge yapıyor mu?
      if (other.isDodging) {
        // Başarılı dodge!
        _showDodgeText();
        removeFromParent();
        return;
      }
      
      // Hasar ver
      other.takeDamage(damage, position);
      _hasHit = true;
      
      // Hit efekti
      _spawnHitEffect();
      removeFromParent();
    }
  }
  
  void _showDodgeText() {
    final dodgeText = _DodgeText(position: position.clone());
    parent?.add(dodgeText);
  }
  
  void _spawnHitEffect() {
    final effect = _HitEffect(position: position.clone(), color: color);
    parent?.add(effect);
  }

  @override
  void render(Canvas canvas) {
    // Trail çiz
    for (int i = 0; i < _trail.length; i++) {
      final trailPos = _trail[i] - position;
      final opacity = (1.0 - i / _maxTrailLength) * 0.5;
      final trailSize = size.x * (1.0 - i / _maxTrailLength) * 0.8;
      
      canvas.drawCircle(
        Offset(trailPos.x + size.x / 2, trailPos.y + size.y / 2),
        trailSize / 2,
        Paint()..color = color.withOpacity(opacity),
      );
    }
    
    // Ana projectile
    final pulse = 1.0 + sin(_animTime * 8) * 0.1;
    final centerOffset = Offset(size.x / 2, size.y / 2);
    
    // Glow
    canvas.drawCircle(
      centerOffset,
      size.x / 2 * pulse * 1.5,
      Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    
    // Core
    canvas.drawCircle(
      centerOffset,
      size.x / 2 * pulse,
      Paint()..color = color,
    );
    
    // Highlight
    canvas.drawCircle(
      Offset(centerOffset.dx - size.x * 0.15, centerOffset.dy - size.x * 0.15),
      size.x * 0.15,
      Paint()..color = Colors.white.withOpacity(0.6),
    );
    
    // Tehlike göstergesi (kırmızı çerçeve)
    canvas.drawCircle(
      centerOffset,
      size.x / 2 * pulse + 2,
      Paint()
        ..color = Colors.red.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

/// Dodge başarılı yazısı
class _DodgeText extends TextComponent {
  double _opacity = 1.0;
  
  _DodgeText({required Vector2 position}) : super(
    text: 'DODGE!',
    position: position,
    anchor: Anchor.center,
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.cyan,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
        ],
      ),
    ),
  );

  @override
  void update(double dt) {
    super.update(dt);
    
    position.y -= 80 * dt;
    _opacity -= dt * 1.5;
    
    if (_opacity <= 0) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    textRenderer = TextPaint(
      style: TextStyle(
        color: Colors.cyan.withOpacity(_opacity),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(_opacity),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
    super.render(canvas);
  }
}

/// Hit efekti
class _HitEffect extends PositionComponent {
  final Color color;
  double _time = 0;
  
  _HitEffect({required Vector2 position, required this.color})
      : super(position: position, size: Vector2.all(60));

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    
    if (_time > 0.3) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = _time / 0.3;
    final radius = size.x / 2 * progress;
    final opacity = 1.0 - progress;
    
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      radius,
      Paint()
        ..color = color.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * (1 - progress),
    );
    
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      radius * 0.6,
      Paint()
        ..color = Colors.white.withOpacity(opacity * 0.5),
    );
  }
}
