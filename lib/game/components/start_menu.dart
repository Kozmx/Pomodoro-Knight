import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

class StartMenu extends StatelessWidget {
  final FocusGame game;
  final VoidCallback onStart;

  const StartMenu({super.key, required this.game, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('game_data');
    final currentLevel = box.get('currentLevel', defaultValue: 1);
    final maxLevel = box.get('maxLevel', defaultValue: 1);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'POMODORO KNIGHT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Current Level: $currentLevel',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Max Level: $maxLevel',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: const Text(
                'START GAME',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
