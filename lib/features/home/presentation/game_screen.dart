import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/game/focus_game.dart';
import 'package:pomodoro_knight/game/services/player_stats_service.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';
import 'package:pomodoro_knight/features/home/presentation/navigation_provider.dart';
import 'package:pomodoro_knight/features/upgrades/presentation/upgrades_provider.dart';
import 'package:pomodoro_knight/features/inventory/presentation/inventory_provider.dart';
import 'package:pomodoro_knight/features/shop/data/mock_shop_items.dart';
import 'package:pomodoro_knight/features/shop/domain/shop_item.dart';

import 'package:pomodoro_knight/game/components/start_menu.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  // Oyunu bir kez oluşturuyoruz ki rebuild'larda sıfırlanmasın
  late final FocusGame _game;

  @override
  void initState() {
    super.initState();
    _game = FocusGame();
  }

  @override
  void dispose() {
    // Ekrandan çıkınca müziği kapat
    GameAudioService().stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Upgrade stat'larını dinle ve oyun servisine aktar
    final upgradesState = ref.watch(upgradesProvider);
    PlayerStatsService().updateStats(
      attackSpeed: upgradesState.attackSpeedMultiplier,
      damage: upgradesState.damageMultiplier,
      maxHealth: upgradesState.maxHealthBonus,
      defense: upgradesState.defenseMultiplier,
      coin: upgradesState.coinMultiplier,
      crit: upgradesState.criticalChance,
    );

    // Equipped weapon'ı dinle ve oyun servisine aktar
    final inventory = ref.watch(inventoryProvider);
    final equippedWeaponId = inventory.equippedWeapon;

    // Equipped weapon'ın stats'larını bul
    if (equippedWeaponId != null) {
      final weapon = mockWeapons.firstWhere(
        (w) => w.id == equippedWeaponId,
        orElse: () => mockWeapons.first, // Default: Knight Sword
      );
      PlayerStatsService().updateEquippedWeapon(
        weaponId: weapon.id,
        baseDamage: weapon.damage,
        attackSpeed: weapon.attackSpeed,
        critBonus: weapon.critBonus,
        specialEffect: weapon.specialEffect,
        type: weapon.weaponType,
        projSpeed: weapon.projectileSpeed,
      );
    } else {
      // Default starter weapon
      PlayerStatsService().updateEquippedWeapon(
        weaponId: 'weapon_starter',
        baseDamage: 10,
        attackSpeed: 1.0,
        critBonus: 0.0,
        specialEffect: 'None',
        type: WeaponType.melee,
      );
    }

    return Scaffold(
      body: GameWidget<FocusGame>(
        game: _game,
        overlayBuilderMap: {
          'StartMenu': (BuildContext context, FocusGame game) {
            return StartMenu(
              game: game,
              onStart: () {
                game.startGame();
              },
            );
          },
          'ElevatorMenu': (BuildContext context, FocusGame game) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'LEVEL COMPLETE',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        game.levelManager.continueToNextLevel();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'Devam Et',
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(navigationIndexProvider.notifier).setIndex(0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'Çalışmaya Dön',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          'GameOver': (BuildContext context, FocusGame game) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        game.resetGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        },
      ),
    );
  }
}
