import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'package:pomodoro_knight/game/focus_game.dart';

/// Skill butonu - XP ile dolan, progress bar'lı
class SkillButton extends PositionComponent with TapCallbacks, HasGameRef<FocusGame> {
  final double radius;
  final VoidCallback? onActivate;
  
  // XP Progress (0.0 - 1.0)
  double _progress = 0.0;
  bool _isReady = false;
  
  // Buff durumu
  bool _isActive = false;
  double _buffTimer = 0;
  final double _buffDuration = 10.0; // 10 saniyelik buff
  
  // Animasyon
  double _pulseTimer = 0;
  
  SkillButton({
    required Vector2 position,
    this.radius = 22,
    this.onActivate,
  }) : super(
    position: position,
    size: Vector2.all(radius * 2),
    anchor: Anchor.center,
  );
  
  bool get isReady => _isReady;
  bool get isActive => _isActive;
  double get progress => _progress;
  
  /// XP ekle (0.0 - 1.0 arası değer döner)
  void addXp(double amount) {
    if (_isActive) return; // Buff aktifken XP toplanmaz
    
    _progress = (_progress + amount).clamp(0.0, 1.0);
    if (_progress >= 1.0) {
      _isReady = true;
    }
  }
  
  /// Skill'i aktifle
  void activate() {
    if (!_isReady || _isActive) return;
    
    _isReady = false;
    _isActive = true;
    _progress = 0.0;
    _buffTimer = _buffDuration;
    
    // Buff'ları uygula
    _applyBuffs();
    
    onActivate?.call();
  }
  
  void _applyBuffs() {
    // Saldırı hızı +50%, hasar +25%, can yenilenmesi
    gameRef.player.applySkillBuff(
      attackSpeedBonus: 0.5,
      damageBonus: 0.25,
      healthRegen: 5.0, // Saniyede 5 can
      duration: _buffDuration,
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _pulseTimer += dt;
    
    if (_isActive) {
      _buffTimer -= dt;
      if (_buffTimer <= 0) {
        _isActive = false;
        _buffTimer = 0;
      }
    }
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    if (_isReady) {
      activate();
    }
    return true;
  }
  
  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    
    // Arka plan (koyu daire)
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress arc (mavi)
    if (_progress > 0 && !_isActive) {
      final progressPaint = Paint()
        ..color = Colors.blue.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        -pi / 2, // Üstten başla
        2 * pi * _progress,
        false,
        progressPaint,
      );
    }
    
    // Buff aktifken kalan süre göster
    if (_isActive) {
      final buffProgress = _buffTimer / _buffDuration;
      final buffPaint = Paint()
        ..color = Colors.orange.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        -pi / 2,
        2 * pi * buffProgress,
        false,
        buffPaint,
      );
      
      // Aktif glow
      final glowPaint = Paint()
        ..color = Colors.orange.withOpacity(0.3 + 0.2 * sin(_pulseTimer * 4))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, radius + 4, glowPaint);
    }
    
    // Hazır olduğunda parlama efekti
    if (_isReady) {
      final glowIntensity = 0.4 + 0.3 * sin(_pulseTimer * 3);
      final glowPaint = Paint()
        ..color = Colors.blue.withOpacity(glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, radius + 6, glowPaint);
    }
    
    // İkon (⚔️ veya ⚡)
    final iconPainter = TextPainter(
      text: TextSpan(
        text: _isActive ? '⚡' : '⚔️',
        style: TextStyle(
          fontSize: radius * 0.9,
          color: _isReady ? Colors.white : Colors.white.withOpacity(0.5),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(center.dx - iconPainter.width / 2, center.dy - iconPainter.height / 2),
    );
    
    // Dış çerçeve
    final borderPaint = Paint()
      ..color = _isReady ? Colors.blue : (_isActive ? Colors.orange : Colors.grey)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
  }
}

/// Dash butonu
class DashButton extends PositionComponent with TapCallbacks, HasGameRef<FocusGame> {
  final double radius;
  
  // Cooldown
  double _cooldown = 0;
  final double _maxCooldown = 2.0; // 2 saniye cooldown
  
  DashButton({
    required Vector2 position,
    this.radius = 22,
  }) : super(
    position: position,
    size: Vector2.all(radius * 2),
    anchor: Anchor.center,
  );
  
  bool get isReady => _cooldown <= 0;
  
  @override
  void update(double dt) {
    super.update(dt);
    if (_cooldown > 0) {
      _cooldown -= dt;
    }
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    if (isReady) {
      _performDash();
    }
    return true;
  }
  
  void _performDash() {
    _cooldown = _maxCooldown;
    gameRef.player.performDash();
  }
  
  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    
    // Arka plan
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);
    canvas.drawCircle(center, radius, bgPaint);
    
    // Cooldown göstergesi
    if (!isReady) {
      final cooldownProgress = _cooldown / _maxCooldown;
      final cooldownPaint = Paint()
        ..color = Colors.grey.withOpacity(0.5);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        -pi / 2,
        2 * pi * cooldownProgress,
        true,
        cooldownPaint,
      );
    }
    
    // İkon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: '💨',
        style: TextStyle(
          fontSize: radius * 0.9,
          color: isReady ? Colors.white : Colors.white.withOpacity(0.4),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(center.dx - iconPainter.width / 2, center.dy - iconPainter.height / 2),
    );
    
    // Dış çerçeve
    final borderPaint = Paint()
      ..color = isReady ? Colors.cyan : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
  }
}

/// Kalkan butonu - basılı tutunca aktif
class ShieldButton extends PositionComponent with TapCallbacks, HasGameRef<FocusGame> {
  final double radius;
  bool _isPressed = false;
  double _pulseTimer = 0;
  
  ShieldButton({
    required Vector2 position,
    this.radius = 22,
  }) : super(
    position: position,
    size: Vector2.all(radius * 2),
    anchor: Anchor.center,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    _isPressed = true;
    gameRef.player.setShield(true);
    return true;
  }
  
  @override
  bool onTapUp(TapUpEvent event) {
    _isPressed = false;
    gameRef.player.setShield(false);
    return true;
  }
  
  @override
  bool onTapCancel(TapCancelEvent event) {
    _isPressed = false;
    gameRef.player.setShield(false);
    return true;
  }
  
  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    
    // Arka plan
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);
    canvas.drawCircle(center, radius, bgPaint);
    
    // Basılıyken glow
    if (_isPressed) {
      final glowIntensity = 0.5 + 0.2 * sin(_pulseTimer * 5);
      final glowPaint = Paint()
        ..color = Colors.blue.withOpacity(glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, radius + 4, glowPaint);
      
      // İç dolgu
      final fillPaint = Paint()
        ..color = Colors.blue.withOpacity(0.4);
      canvas.drawCircle(center, radius - 4, fillPaint);
    }
    
    // İkon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: '🛡️',
        style: TextStyle(
          fontSize: radius * 0.85,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(center.dx - iconPainter.width / 2, center.dy - iconPainter.height / 2),
    );
    
    // Dış çerçeve
    final borderPaint = Paint()
      ..color = _isPressed ? Colors.blue : Colors.blueGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
  }
}

/// Saldırı butonu - yeniden tasarlanmış
class AttackButton extends PositionComponent with TapCallbacks, HasGameRef<FocusGame> {
  final double radius;
  bool _isPressed = false;
  
  AttackButton({
    required Vector2 position,
    this.radius = 30,
  }) : super(
    position: position,
    size: Vector2.all(radius * 2),
    anchor: Anchor.center,
  );
  
  @override
  bool onTapDown(TapDownEvent event) {
    _isPressed = true;
    gameRef.player.attack();
    return true;
  }
  
  @override
  bool onTapUp(TapUpEvent event) {
    _isPressed = false;
    return true;
  }
  
  @override
  bool onTapCancel(TapCancelEvent event) {
    _isPressed = false;
    return true;
  }
  
  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    
    // Arka plan
    final bgPaint = Paint()
      ..color = Colors.red.withOpacity(_isPressed ? 0.8 : 0.5);
    canvas.drawCircle(center, radius, bgPaint);
    
    // Basılıyken efekt
    if (_isPressed) {
      final glowPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, radius + 4, glowPaint);
    }
    
    // İkon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: '⚔️',
        style: TextStyle(
          fontSize: radius * 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(center.dx - iconPainter.width / 2, center.dy - iconPainter.height / 2),
    );
    
    // Dış çerçeve
    final borderPaint = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, borderPaint);
  }
}
