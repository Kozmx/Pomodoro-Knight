import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:pomodoro_knight/game/focus_game.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';

/// XP toplama efekti - düşman öldüğünde görünen floating text
class XpPopup extends PositionComponent with HasGameRef<FocusGame> {
  final int xpAmount;
  double _lifeTime = 0;
  final double _duration = 1.2;
  
  // Animasyon
  double _scale = 0.0;
  
  XpPopup({
    required Vector2 position,
    required this.xpAmount,
  }) : super(
          position: position,
          size: Vector2.zero(),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;

    // Pop-in animasyonu (ilk 0.15 saniye)
    if (_lifeTime < 0.15) {
      _scale = (_lifeTime / 0.15) * 1.3; // Overshoot
    } else if (_lifeTime < 0.25) {
      _scale = 1.3 - ((_lifeTime - 0.15) / 0.1) * 0.3; // Settle to 1.0
    } else {
      _scale = 1.0;
    }

    // Yukarı doğru yavaşça hareket
    position.y -= 40 * dt;

    if (_lifeTime >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fade out (son 0.3 saniye)
    double opacity = 1.0;
    if (_lifeTime > _duration - 0.3) {
      opacity = ((_duration - _lifeTime) / 0.3).clamp(0.0, 1.0);
    }

    canvas.save();
    canvas.scale(_scale, _scale);

    // Glow efekti
    final glowPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(opacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '+$xpAmount XP',
        style: TextStyle(
          color: Colors.greenAccent.withOpacity(opacity),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(opacity * 0.8),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
            Shadow(
              color: Colors.green.withOpacity(opacity * 0.5),
              blurRadius: 10,
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    
    // Glow background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: textPainter.width + 16,
          height: textPainter.height + 8,
        ),
        const Radius.circular(8),
      ),
      glowPaint,
    );
    
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }
}

/// Ölüm patlama efekti - basit daire genişlemesi
class DeathBurstEffect extends PositionComponent {
  double _lifeTime = 0;
  final double _duration = 0.4;
  final Color color;
  final double maxRadius;
  
  DeathBurstEffect({
    required Vector2 position,
    this.color = Colors.greenAccent,
    this.maxRadius = 60,
  }) : super(
          position: position,
          size: Vector2.zero(),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;

    if (_lifeTime >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_lifeTime / _duration).clamp(0.0, 1.0);
    final radius = maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // Dış halka
    final ringPaint = Paint()
      ..color = color.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * (1 - progress);
    canvas.drawCircle(Offset.zero, radius, ringPaint);

    // İç dolgu (daha şeffaf)
    final fillPaint = Paint()
      ..color = color.withOpacity(opacity * 0.3);
    canvas.drawCircle(Offset.zero, radius * 0.6, fillPaint);
    
    // Parlak merkez
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.7);
    canvas.drawCircle(Offset.zero, radius * 0.2, centerPaint);
  }
}

/// Sparkle parçacıkları - çok hafif, sadece birkaç tane
class XpSparkle extends PositionComponent {
  final Vector2 velocity;
  double _lifeTime = 0;
  final double _duration = 0.5;
  final Color color;
  
  XpSparkle({
    required Vector2 position,
    required this.velocity,
    this.color = Colors.greenAccent,
  }) : super(
          position: position,
          size: Vector2(6, 6),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;
    
    // Hareket + yavaşlama
    position += velocity * dt;
    velocity.scale(0.95);

    if (_lifeTime >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = (1.0 - (_lifeTime / _duration)).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withOpacity(opacity);
    
    // Basit kare (daire yerine - daha hızlı render)
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 4, height: 4),
      paint,
    );
  }
}

/// XP toplama efektlerini spawn eden fonksiyon
void spawnXpEffect({
  required FocusGame gameRef,
  required Vector2 position,
  int xpAmount = 3,
}) {
  // 1. Ses çal
  GameAudioService().playXpCollect();
  
  // 2. Patlama efekti
  gameRef.world.add(DeathBurstEffect(
    position: position.clone(),
    color: Colors.greenAccent,
    maxRadius: 50,
  ));
  
  // 3. XP popup text
  gameRef.world.add(XpPopup(
    position: position.clone() + Vector2(0, -30),
    xpAmount: xpAmount,
  ));
  
  // 4. Birkaç sparkle (sadece 4 tane - performans için)
  final random = Random();
  for (int i = 0; i < 4; i++) {
    final angle = (i / 4) * 2 * pi + random.nextDouble() * 0.5;
    final speed = 80 + random.nextDouble() * 40;
    
    gameRef.world.add(XpSparkle(
      position: position.clone(),
      velocity: Vector2(cos(angle) * speed, sin(angle) * speed - 50),
      color: i.isEven ? Colors.greenAccent : Colors.white,
    ));
  }
  
  // 5. Skill butonuna XP ekle
  gameRef.addXpToSkill(xpAmount);
}
