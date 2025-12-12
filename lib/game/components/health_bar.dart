import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

class HealthBar extends PositionComponent with HasGameRef<FocusGame> {
  static final _paintBorder = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  
  static final _paintBackground = Paint()..color = Colors.red.withOpacity(0.5);
  static final _paintHealth = Paint()..color = Colors.green;

  HealthBar() : super(position: Vector2(20, 50), size: Vector2(200, 20));

  @override
  void render(Canvas canvas) {
    final player = gameRef.player;
    final healthPercent = (player.currentHealth / player.maxHealth).clamp(0.0, 1.0);
    
    // Background
    canvas.drawRect(size.toRect(), _paintBackground);

    // Health
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x * healthPercent, size.y), 
      _paintHealth
    );

    // Border
    canvas.drawRect(size.toRect(), _paintBorder);

    // Can miktarı yazısı (bar içinde ortalanmış)
    final healthText = '${player.currentHealth.toInt()} / ${player.maxHealth.toInt()}';
    final textPainter = TextPainter(
      text: TextSpan(
        text: healthText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2),
    );
  }
}
