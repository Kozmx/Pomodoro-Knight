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
  final bool isBossFight;
  double _lifeTime = 0;
  final double _duration = 2.5;
  double _alpha = 0;
  double _scale = 0.5;

  LevelTransitionOverlay({
    required this.level,
    required Vector2 screenSize,
    this.isBossFight = false,
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
    final bgColor = isBossFight ? Colors.red.shade900 : Colors.black;
    final bgPaint = Paint()
      ..color = bgColor.withOpacity(_alpha * 0.7);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 500, height: 180),
      bgPaint,
    );

    TextPainter textPainter;
    
    if (isBossFight) {
      // Boss Fight yazısı
      textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '⚔️ BOSS FIGHT ⚔️\n',
              style: TextStyle(
                fontFamily: 'Minecraftia',
                color: Colors.red.withOpacity(_alpha),
                fontSize: 42,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.redAccent.withOpacity(_alpha * 0.8),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            TextSpan(
              text: 'SLIME KING',
              style: TextStyle(
                fontFamily: 'Minecraftia',
                color: Colors.yellow.withOpacity(_alpha),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.orange.withOpacity(_alpha * 0.8),
                    blurRadius: 15,
                  ),
                ],
              ),
            ),
          ],
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );
    } else {
      // Normal kat yazısı
      textPainter = TextPainter(
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
    }

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

/// Boss Health Bar - ekranın üstünde gösterilir
class BossHealthBar extends PositionComponent with HasGameRef {
  final String bossName;
  final double maxHealth;
  double currentHealth;
  
  double _animatedHealth = 1.0;
  double _damageFlash = 0;
  double _pulseTime = 0;
  
  BossHealthBar({
    required this.bossName,
    required this.maxHealth,
    required this.currentHealth,
    required Vector2 screenSize,
  }) : super(
          position: Vector2(screenSize.x / 2, 40),
          size: Vector2(screenSize.x * 0.6, 40),
          anchor: Anchor.center,
          priority: 500,
        );

  void updateHealth(double newHealth) {
    if (newHealth < currentHealth) {
      _damageFlash = 1.0;
    }
    currentHealth = newHealth;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    _pulseTime += dt;
    
    // Smooth health animation
    final targetHealth = currentHealth / maxHealth;
    _animatedHealth += (targetHealth - _animatedHealth) * dt * 5;
    
    // Damage flash fade
    if (_damageFlash > 0) {
      _damageFlash -= dt * 3;
    }
  }

  @override
  void render(Canvas canvas) {
    final barWidth = size.x;
    final barHeight = 20.0;
    final barY = size.y - barHeight;
    
    // Arka plan
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barY, barWidth, barHeight),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.black.withOpacity(0.7),
    );
    
    // Kırmızı hasar göstergesi (gecikmiş)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, barY + 2, (barWidth - 4) * _animatedHealth, barHeight - 4),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.red.shade900,
    );
    
    // Ana can barı
    final healthPercent = (currentHealth / maxHealth).clamp(0.0, 1.0);
    Color healthColor = Colors.green;
    if (healthPercent < 0.3) {
      healthColor = Colors.red;
    } else if (healthPercent < 0.6) {
      healthColor = Colors.orange;
    }
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, barY + 2, (barWidth - 4) * healthPercent, barHeight - 4),
        const Radius.circular(8),
      ),
      Paint()..color = healthColor,
    );
    
    // Flash efekti
    if (_damageFlash > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, barY, barWidth, barHeight),
          const Radius.circular(10),
        ),
        Paint()..color = Colors.white.withOpacity(_damageFlash * 0.5),
      );
    }
    
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barY, barWidth, barHeight),
        const Radius.circular(10),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    // Boss ismi
    final pulse = 1.0 + sin(_pulseTime * 2) * 0.05;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '👑 $bossName 👑',
        style: TextStyle(
          fontFamily: 'Minecraftia',
          color: Colors.yellow,
          fontSize: 16 * pulse,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
            Shadow(color: Colors.orange, blurRadius: 8),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((barWidth - textPainter.width) / 2, 0),
    );
    
    // HP yazısı
    final hpPainter = TextPainter(
      text: TextSpan(
        text: '${currentHealth.toInt()} / ${maxHealth.toInt()}',
        style: const TextStyle(
          fontFamily: 'Minecraftia',
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    hpPainter.layout();
    hpPainter.paint(
      canvas,
      Offset((barWidth - hpPainter.width) / 2, barY + 4),
    );
  }
}
