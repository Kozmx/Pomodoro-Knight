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
    // Position at top right
    anchor = Anchor.topRight;
    position = Vector2(gameRef.size.x - 20, 50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Keep it at right side if screen resizes
    position.x = gameRef.size.x - 20;

    // Update text from LevelManager
    text = 'Floor: ${gameRef.levelManager.currentLevel}';
  }
}
