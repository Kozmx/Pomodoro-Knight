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
