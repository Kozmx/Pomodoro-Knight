import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Hasar miktarını gösteren uçan yazı
class DamageText extends PositionComponent {
  final double damage;
  final Color color;
  double _lifeTime = 0;
  final double _duration = 1.0; // 1 saniye boyunca görünsün

  DamageText({
    required Vector2 position,
    required this.damage,
    this.color = Colors.white,
  }) : super(
          position: position,
          size: Vector2.zero(),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;

    // Yukarı doğru hareket et
    position.y -= 50 * dt;

    // Süre dolunca yok ol
    if (_lifeTime >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Opacity fade out efekti
    final opacity = (1.0 - (_lifeTime / _duration)).clamp(0.0, 1.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: damage.toInt().toString(),
        style: TextStyle(
          color: color.withOpacity(opacity),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(opacity),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}
