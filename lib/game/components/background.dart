import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class StarBackground extends PositionComponent {
  static final _paint = Paint()..color = Colors.white.withOpacity(0.8);
  final Random _rnd = Random();
  final List<Vector2> _stars = [];

  double scrollSpeed = 0.0;

  StarBackground() : super(priority: -10);

  @override
  Future<void> onLoad() async {
    size = Vector2(2000, 1000); // Geniş bir dünya (2000 birim genişlik)
    for (int i = 0; i < 200; i++) {
      _stars.add(
        Vector2(_rnd.nextDouble() * size.x, _rnd.nextDouble() * size.y),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (scrollSpeed > 0) {
      for (final star in _stars) {
        star.y += scrollSpeed * dt;
        if (star.y > size.y) {
          star.y = 0;
          star.x = _rnd.nextDouble() * size.x;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Koyu uzay arka planı
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFF0D0D1A));

    // Yıldızları çiz
    for (final star in _stars) {
      canvas.drawCircle(star.toOffset(), 2, _paint);
    }

    // Zemin çizgisi (Görsel olarak)
    canvas.drawRect(
      Rect.fromLTWH(0, 800, size.x, 200),
      Paint()..color = const Color(0xFF2A2A2A),
    );
  }
}
