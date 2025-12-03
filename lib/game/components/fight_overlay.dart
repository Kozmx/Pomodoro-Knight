import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

class FightOverlay extends PositionComponent with HasGameRef<FocusGame> {
  late TextComponent _textComponent;
  final VoidCallback? onFinish;

  FightOverlay({this.onFinish});

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    position = gameRef.size / 2; // Center of the screen (viewport)

    _textComponent = TextComponent(
      text: 'FIGHT!',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 64,
          color: Colors.red,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
    _textComponent.anchor = Anchor.center;
    add(_textComponent);

    // Add effects: Scale up and then Fade out
    add(
      ScaleEffect.to(
        Vector2.all(1.5),
        EffectController(duration: 0.2, curve: Curves.easeOut),
        onComplete: () {
          // Wait a bit then fade out
          add(
            TimerComponent(
              period: 0.5,
              removeOnFinish: true,
              onTick: () {
                add(
                  OpacityEffect.fadeOut(
                    EffectController(duration: 0.5),
                    onComplete: () {
                      removeFromParent();
                      onFinish?.call();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
