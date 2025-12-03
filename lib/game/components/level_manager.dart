import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/components/elevator.dart';
import 'package:pomodoro_knight/game/components/enemy.dart';
import 'package:pomodoro_knight/game/components/flying_enemy.dart';
import 'package:pomodoro_knight/game/focus_game.dart';

import 'package:shared_preferences/shared_preferences.dart';

enum LevelState { playing, transitioning, bossFight }

class LevelManager extends Component with HasGameRef<FocusGame> {
  int currentLevel = 1;
  int enemiesKilled = 0;
  int totalEnemies = 0;
  LevelState state = LevelState.playing;

  final Random _rnd = Random();

  @override
  Future<void> onLoad() async {
    print("LevelManager: onLoad started");
    try {
      await _loadLevel();
      print("LevelManager: Level loaded: $currentLevel");
    } catch (e) {
      print("LevelManager: Error loading level: $e");
      currentLevel = 1;
    }
    startLevel();
  }

  Future<void> _loadLevel() async {
    final prefs = await SharedPreferences.getInstance();
    currentLevel = prefs.getInt('currentLevel') ?? 1;
  }

  Future<void> _saveLevel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentLevel', currentLevel);
  }

  void startLevel() {
    print("LevelManager: startLevel called for level $currentLevel");
    state = LevelState.playing;
    enemiesKilled = 0;

    // Calculate enemies for this level (simple progression)
    int enemyCount = 2 + currentLevel;
    int flyingEnemyCount = 1 + (currentLevel ~/ 2);
    totalEnemies = enemyCount + flyingEnemyCount;

    print(
      "LevelManager: Spawning $enemyCount ground and $flyingEnemyCount flying enemies",
    );

    _spawnEnemies(enemyCount, flyingEnemyCount);
  }

  void _spawnEnemies(int ground, int flying) {
    final playerPos = gameRef.player.position;
    final minDistance = 400.0;

    // Difficulty Scaling
    // Base HP: 30, +10 per level
    // Base Damage: 10, +2 per level (passed to enemy, though enemy deals damage via collision currently)
    final double enemyHealth = 30.0 + (currentLevel - 1) * 10.0;
    final double enemyDamage = 10.0 + (currentLevel - 1) * 2.0;

    // Spawn Ground Enemies
    for (int i = 0; i < ground; i++) {
      Vector2 spawnPos;
      int attempts = 0;
      do {
        spawnPos = Vector2(100 + _rnd.nextDouble() * 1800, 750);
        attempts++;
      } while (spawnPos.distanceTo(playerPos) < minDistance && attempts < 20);

      print(
        "LevelManager: Spawning Ground Enemy at $spawnPos after $attempts attempts",
      );

      gameRef.world.add(
        Enemy(
          player: gameRef.player,
          maxHealth: enemyHealth,
          damage: enemyDamage,
        )..position = spawnPos,
      );
    }

    // Spawn Flying Enemies
    for (int i = 0; i < flying; i++) {
      Vector2 spawnPos;
      int attempts = 0;
      do {
        spawnPos = Vector2(
          100 + _rnd.nextDouble() * 1800,
          300 + _rnd.nextDouble() * 300,
        );
        attempts++;
      } while (spawnPos.distanceTo(playerPos) < minDistance && attempts < 20);

      print(
        "LevelManager: Spawning Flying Enemy at $spawnPos after $attempts attempts",
      );

      gameRef.world.add(
        FlyingEnemy(
          player: gameRef.player,
          maxHealth: enemyHealth * 0.8, // Flying enemies have less HP
          damage: enemyDamage,
        )..position = spawnPos,
      );
    }
  }

  void onEnemyKilled() {
    enemiesKilled++;
    if (enemiesKilled >= totalEnemies) {
      _spawnElevator();
    }
  }

  void _spawnElevator() {
    // Spawn elevator in the middle of the map
    final elevator = Elevator()
      ..position = Vector2(gameRef.background.size.x / 2, 750);
    gameRef.world.add(elevator);

    // Optional: Show a message or indicator
  }

  void startAscension() {
    if (state == LevelState.transitioning) return;
    state = LevelState.transitioning;

    // Disable player movement
    gameRef.player.canMove = false;

    // 1. Zoom In (Smoothly)
    gameRef.add(_ZoomEffect(2.0, 2.0, curve: Curves.easeInOut));

    // 2. Animate Background (Simulate going up)
    gameRef.background.scrollSpeed = 500.0; // Speed up stars downwards

    // 3. Show Menu
    gameRef.overlays.add('ElevatorMenu');
  }

  void continueToNextLevel() {
    gameRef.overlays.remove('ElevatorMenu');

    // Wait a moment for zoom out or just proceed
    _nextLevel();
  }

  void _nextLevel() {
    currentLevel++;
    _saveLevel();

    // Reset Background
    gameRef.background.scrollSpeed = 0.0;

    // Remove Elevator
    gameRef.world.children.whereType<Elevator>().forEach(
      (e) => e.removeFromParent(),
    );

    // Start new level
    startLevel();

    // Reset player position to center
    gameRef.player.position = Vector2(1000, 750);

    // Re-enable player movement immediately
    gameRef.player.canMove = true;

    // Zoom Out (Smoothly)
    // Ensure we start from the zoomed in state logically if needed,
    // but the effect works from current zoom.
    gameRef.add(_ZoomEffect(1.0, 1.5, curve: Curves.easeOut));
  }
}

class _ZoomEffect extends Component with HasGameRef<FocusGame> {
  final double targetZoom;
  final double duration;
  final Curve curve;
  double _timer = 0;
  double _startZoom = 1.0;

  _ZoomEffect(this.targetZoom, this.duration, {this.curve = Curves.linear});

  @override
  Future<void> onLoad() async {
    _startZoom = gameRef.camera.viewfinder.zoom;
  }

  @override
  void update(double dt) {
    _timer += dt;
    double t = (_timer / duration).clamp(0.0, 1.0);
    double curveValue = curve.transform(t);
    gameRef.camera.viewfinder.zoom =
        _startZoom + (targetZoom - _startZoom) * curveValue;

    if (t >= 1.0) removeFromParent();
  }
}
