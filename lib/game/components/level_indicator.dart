import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

class LevelIndicator extends TextComponent with HasGameRef<FocusGame> {
  LevelIndicator()
    : super(
        text: 'Floor: 1',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
      );

  @override
  Future<void> onLoad() async {
    // Position at top center
    anchor = Anchor.topCenter;
    position = Vector2(gameRef.size.x / 2, 50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Keep it centered if screen resizes (optional)
    position.x = gameRef.size.x / 2;

    // Update text from LevelManager
    text = 'Floor: ${gameRef.levelManager.currentLevel}';
  }
}
