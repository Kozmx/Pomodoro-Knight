import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

// TEST: Kat seçme özelliği
const bool _testModeEnabled = true;

class StartMenu extends StatefulWidget {
  final FocusGame game;
  final VoidCallback onStart;

  const StartMenu({super.key, required this.game, required this.onStart});

  @override
  State<StartMenu> createState() => _StartMenuState();
}

class _StartMenuState extends State<StartMenu> {
  int _selectedLevel = 1;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('game_data');
    _selectedLevel = box.get('currentLevel', defaultValue: 1);
  }

  // TEST: Seçilen kata git
  void _startWithSelectedLevel() {
    final box = Hive.box('game_data');
    box.put('currentLevel', _selectedLevel);
    widget.game.levelManager.currentLevel = _selectedLevel;
    widget.onStart();
  }

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
                fontFamily: 'Pixelmania',
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
            
            // TEST: Kat seçici
            if (_testModeEnabled) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple, width: 1),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🧪 TEST: Kat Seç',
                      style: TextStyle(color: Colors.purple, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedLevel > 1) _selectedLevel--;
                            });
                          },
                          icon: const Icon(Icons.remove, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Kat $_selectedLevel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedLevel++;
                            });
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _testModeEnabled ? _startWithSelectedLevel : widget.onStart,
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
