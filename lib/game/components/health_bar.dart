import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

class HealthBar extends PositionComponent with HasGameRef<FocusGame> {
  // Dynamic island/notch için güvenli alan - 60px yeterli olmalı
  static const double safeAreaTop = 60.0;
  
  HealthBar() : super(position: Vector2(40, safeAreaTop), size: Vector2(180, 28));

  @override
  void render(Canvas canvas) {
    final player = gameRef.player;
    final healthPercent = (player.currentHealth / player.maxHealth).clamp(0.0, 1.0);
    
    // Piksel kalınlığı
    const double px = 2.0;
    
    // Dış çerçeve - koyu gri
    final outerBorder = Paint()..color = const Color(0xFF2D2D2D);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), outerBorder);
    
    // İç alan - siyah arka plan
    final innerBg = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRect(Rect.fromLTWH(px, px, size.x - px * 2, size.y - px * 2), innerBg);
    
    // Can barı arka planı - koyu kırmızı
    final healthBg = Paint()..color = const Color(0xFF4A1515);
    canvas.drawRect(
      Rect.fromLTWH(px * 2, px * 2, size.x - px * 4, size.y - px * 4),
      healthBg,
    );
    
    // Can barı doluluk - gradient kırmızı→yeşil
    final healthWidth = (size.x - px * 4) * healthPercent;
    if (healthWidth > 0) {
      // Renk canına göre değişir
      Color healthColor;
      if (healthPercent > 0.6) {
        healthColor = const Color(0xFF22B14C); // Yeşil
      } else if (healthPercent > 0.3) {
        healthColor = const Color(0xFFFFAA00); // Turuncu
      } else {
        healthColor = const Color(0xFFED1C24); // Kırmızı
      }
      
      final healthPaint = Paint()..color = healthColor;
      canvas.drawRect(
        Rect.fromLTWH(px * 2, px * 2, healthWidth, size.y - px * 4),
        healthPaint,
      );
      
      // Highlight - üst kısımda açık çizgi
      final highlight = Paint()..color = Colors.white.withOpacity(0.3);
      canvas.drawRect(
        Rect.fromLTWH(px * 2, px * 2, healthWidth, px * 2),
        highlight,
      );
    }
    
    // Piksel köşeler - 3D görünüm
    final cornerDark = Paint()..color = const Color(0xFF1A1A1A);
    final cornerLight = Paint()..color = const Color(0xFF4A4A4A);
    
    // Sol üst köşe - açık
    canvas.drawRect(Rect.fromLTWH(0, 0, px, px), cornerLight);
    // Sağ alt köşe - koyu
    canvas.drawRect(Rect.fromLTWH(size.x - px, size.y - px, px, px), cornerDark);
    
    // Can miktarı yazısı - Minecraftia font
    final healthText = '${player.currentHealth.toInt()}/${player.maxHealth.toInt()}';
    final textPainter = TextPainter(
      text: TextSpan(
        text: healthText,
        style: const TextStyle(
          fontFamily: 'Minecraftia',
          color: Colors.white,
          fontSize: 10,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 0, offset: Offset(1, 1)),
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
    
    // Kalp ikonu - sol tarafta
    final heartPainter = TextPainter(
      text: const TextSpan(
        text: '❤',
        style: TextStyle(
          color: Color(0xFFED1C24),
          fontSize: 16,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 0, offset: Offset(1, 1)),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    heartPainter.layout();
    heartPainter.paint(canvas, Offset(-22, (size.y - heartPainter.height) / 2));
  }
}
