import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/player.dart';
import 'package:pomodoro_knight/game/components/level_manager.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

class Elevator extends PositionComponent
    with CollisionCallbacks, HasGameRef<FocusGame> {
  Elevator() : super(size: Vector2(100, 20), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = Colors.cyanAccent);

    // Glow effect
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..color = Colors.cyanAccent.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player) {
      // Find LevelManager and trigger ascension
      gameRef.world.children
          .query<LevelManager>()
          .firstOrNull
          ?.startAscension();
    }
  }
}

/// Asansöre çıkmak için rampa/merdiven
class Ramp extends PositionComponent with HasGameRef<FocusGame> {
  Ramp({
    required Vector2 startPos,
    required Vector2 endPos,
  }) : _startPos = startPos,
       _endPos = endPos,
       super(priority: -5);

  final Vector2 _startPos;
  final Vector2 _endPos;

  @override
  Future<void> onLoad() async {
    position = _startPos;
    size = Vector2(
      (_endPos.x - _startPos.x).abs() + 40,
      (_startPos.y - _endPos.y).abs() + 20,
    );
    anchor = Anchor.bottomLeft;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.brown.shade700
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.brown.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Rampa şekli (eğimli dikdörtgen)
    final path = Path();
    path.moveTo(0, size.y); // Sol alt
    path.lineTo(size.x, size.y); // Sağ alt
    path.lineTo(size.x, 0); // Sağ üst (yüksek)
    path.lineTo(0, size.y - 20); // Sol üst (alçak)
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Merdiven çizgileri
    final stepPaint = Paint()
      ..color = Colors.brown.shade800
      ..strokeWidth = 2;

    final stepCount = 8;
    for (int i = 1; i < stepCount; i++) {
      final t = i / stepCount;
      final x = size.x * t;
      final yBottom = size.y;
      final yTop = size.y - (size.y - 20) * t - 20;
      canvas.drawLine(Offset(x, yTop), Offset(x, yBottom), stepPaint);
    }
  }

  /// Rampa üzerindeki Y pozisyonunu hesapla (player için)
  double getYAtX(double worldX) {
    final localX = worldX - position.x;
    if (localX < 0 || localX > size.x) return double.infinity;
    
    // Rampa eğimi: soldan sağa yükseliyor
    final t = localX / size.x;
    final rampY = position.y - (size.y - 20) * t - 20;
    return rampY;
  }
}

/// Düz platform (rampa ucunda veya asansör altında)
class Platform extends PositionComponent with HasGameRef<FocusGame> {
  Platform({
    required Vector2 pos,
    required double width,
    double height = 20,
  }) : _width = width,
       _height = height,
       super(priority: -5) {
    position = pos;
  }

  final double _width;
  final double _height;
  
  late double platformY;

  @override
  Future<void> onLoad() async {
    size = Vector2(_width, _height);
    anchor = Anchor.topLeft;
    platformY = position.y;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.brown.shade600
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.brown.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Platform dikdörtgen
    canvas.drawRect(size.toRect(), paint);
    canvas.drawRect(size.toRect(), borderPaint);
    
    // Üst çizgi (parlak kenar)
    canvas.drawLine(
      const Offset(0, 2),
      Offset(size.x, 2),
      Paint()
        ..color = Colors.brown.shade400
        ..strokeWidth = 2,
    );
  }

  /// Platform üzerindeki Y pozisyonunu hesapla
  double getYAtX(double worldX) {
    if (worldX < position.x || worldX > position.x + size.x) {
      return double.infinity;
    }
    return platformY;
  }
}
