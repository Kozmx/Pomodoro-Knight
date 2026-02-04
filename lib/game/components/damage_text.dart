import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Hasar miktarını gösteren uçan yazı - parlama efektli
class DamageText extends PositionComponent {
  final double damage;
  final bool isCritical;
  double _lifeTime = 0;
  final double _duration = 1.0;
  
  // Pop-in animasyon
  double _scale = 0.0;
  
  // Rastgele yatay hareket
  late double _horizontalDrift;

  DamageText({
    required Vector2 position,
    required this.damage,
    this.isCritical = false,
  }) : super(
          position: position,
          size: Vector2.zero(),
          anchor: Anchor.center,
        ) {
    // Rastgele sağa veya sola kayma (-20 ile +20 arası)
    _horizontalDrift = (damage.hashCode % 40 - 20).toDouble();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;

    // Pop-in animasyonu (ilk 0.1 saniye)
    if (_lifeTime < 0.1) {
      _scale = (_lifeTime / 0.1) * 1.4; // Overshoot
    } else if (_lifeTime < 0.2) {
      _scale = 1.4 - ((_lifeTime - 0.1) / 0.1) * 0.4; // Settle to 1.0
    } else {
      _scale = 1.0;
    }

    // Yukarı + hafif yana hareket
    position.y -= 60 * dt;
    position.x += _horizontalDrift * dt * 0.5;

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

    // Renk seçimi
    final Color mainColor = isCritical ? Colors.yellow : Colors.redAccent;
    final Color glowColor = isCritical ? Colors.orange : Colors.red;
    final double fontSize = isCritical ? 24.0 : 18.0;

    // Glow efekti (arka plan)
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(opacity * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    final text = isCritical ? 'CRIT! -${damage.toInt()}' : '-${damage.toInt()} HP';
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Minecraftia',
          color: mainColor.withOpacity(opacity),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            // Dış glow
            Shadow(
              color: glowColor.withOpacity(opacity * 0.8),
              blurRadius: 8,
            ),
            // Alt gölge
            Shadow(
              color: Colors.black.withOpacity(opacity * 0.9),
              blurRadius: 2,
              offset: const Offset(1, 2),
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    
    // Glow background circle
    canvas.drawCircle(
      Offset.zero,
      textPainter.width * 0.4,
      glowPaint,
    );
    
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }
}
