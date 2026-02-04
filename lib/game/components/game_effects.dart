import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Can yenilenme efekti - yeşil +HP yazısı
class HealText extends PositionComponent {
  final double amount;
  double _lifeTime = 0;
  final double _duration = 1.0;
  double _scale = 0.0;

  HealText({
    required Vector2 position,
    required this.amount,
  }) : super(
          position: position,
          size: Vector2.zero(),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;

    // Pop-in animasyonu
    if (_lifeTime < 0.1) {
      _scale = (_lifeTime / 0.1) * 1.3;
    } else if (_lifeTime < 0.2) {
      _scale = 1.3 - ((_lifeTime - 0.1) / 0.1) * 0.3;
    } else {
      _scale = 1.0;
    }

    // Yukarı hareket
    position.y -= 35 * dt;

    if (_lifeTime >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    double opacity = 1.0;
    if (_lifeTime > _duration - 0.3) {
      opacity = ((_duration - _lifeTime) / 0.3).clamp(0.0, 1.0);
    }

    canvas.save();
    canvas.scale(_scale, _scale);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '+${amount.toInt()} HP',
        style: TextStyle(
          fontFamily: 'Minecraftia',
          color: Colors.greenAccent.withOpacity(opacity),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.green.shade900.withOpacity(opacity),
              blurRadius: 4,
              offset: const Offset(1, 1),
            ),
            Shadow(
              color: Colors.greenAccent.withOpacity(opacity * 0.5),
              blurRadius: 8,
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

    canvas.restore();
  }
}

/// Kat geçiş animasyonu - büyük yazı ortada
class LevelTransitionOverlay extends PositionComponent {
  final int level;
  double _lifeTime = 0;
  final double _duration = 2.5;
  double _alpha = 0;
  double _scale = 0.5;

  LevelTransitionOverlay({
    required this.level,
    required Vector2 screenSize,
  }) : super(
          position: screenSize / 2,
          size: Vector2.zero(),
          anchor: Anchor.center,
          priority: 1000,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;

    // Fade in (0-0.5s)
    if (_lifeTime < 0.5) {
      _alpha = (_lifeTime / 0.5).clamp(0.0, 1.0);
      _scale = 0.5 + 0.5 * _alpha;
    }
    // Stay (0.5-2s)
    else if (_lifeTime < 2.0) {
      _alpha = 1.0;
      _scale = 1.0;
    }
    // Fade out (2-2.5s)
    else {
      _alpha = ((2.5 - _lifeTime) / 0.5).clamp(0.0, 1.0);
      _scale = 1.0 + 0.2 * (1 - _alpha);
    }

    if (_lifeTime >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.scale(_scale, _scale);

    // Arka plan blur
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(_alpha * 0.6);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 400, height: 150),
      bgPaint,
    );

    // "KAT X" yazısı
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'KAT ',
            style: TextStyle(
              fontFamily: 'Minecraftia',
              color: Colors.white.withOpacity(_alpha),
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: '$level',
            style: TextStyle(
              fontFamily: 'Minecraftia',
              color: Colors.cyanAccent.withOpacity(_alpha),
              fontSize: 64,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.cyan.withOpacity(_alpha * 0.8),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }
}

/// Asansör hazır bildirimi - oyuncunun üzerinde takip eder
class ElevatorReadyIndicator extends PositionComponent with HasGameRef {
  double _pulseTimer = 0;
  double _arrowTimer = 0;
  bool _isDismissed = false;
  double _fadeOut = 1.0;

  ElevatorReadyIndicator({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(220, 50),
          anchor: Anchor.center,
          priority: 100,
        );

  void dismiss() {
    _isDismissed = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;
    _arrowTimer += dt;

    // Oyuncuyu takip et - biraz yukarısında
    try {
      final player = (gameRef as dynamic).player;
      if (player != null) {
        position.x = player.position.x;
        position.y = player.position.y - 80;
      }
    } catch (_) {}

    if (_isDismissed) {
      _fadeOut -= dt * 3;
      if (_fadeOut <= 0) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.8 + 0.2 * sin(_pulseTimer * 3);
    final arrowOffset = sin(_arrowTimer * 5) * 5; // Ok animasyonu

    // Arka plan
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7 * _fadeOut);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    // Border - yeşil glow
    final borderPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(pulse * _fadeOut)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(8),
      ),
      borderPaint,
    );

    // "FLOOR COMPLETE" yazısı
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'FLOOR COMPLETE',
        style: TextStyle(
          fontFamily: 'Minecraftia',
          color: Colors.greenAccent.withOpacity(_fadeOut),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.green.withOpacity(0.8 * _fadeOut),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, 8),
    );

    // Sağa ok "→→→" animasyonlu - asansör sağda
    final arrowPainter = TextPainter(
      text: TextSpan(
        text: '▶ ▶ ▶',
        style: TextStyle(
          fontFamily: 'Minecraftia',
          color: Colors.yellowAccent.withOpacity(pulse * _fadeOut),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.orange.withOpacity(0.8 * _fadeOut),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    arrowPainter.layout();
    arrowPainter.paint(
      canvas,
      Offset((size.x - arrowPainter.width) / 2 + arrowOffset, 28),
    );
  }
}
