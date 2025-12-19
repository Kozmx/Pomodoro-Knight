import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pomodoro_knight/logic/upgrades/upgrades_state.dart';

class UpgradesNotifier extends Notifier<UpgradesState> {
  late Box _box;

  @override
  UpgradesState build() {
    _box = Hive.box('game_data');

    // Hive'dan upgrade level'ları yükle
    final dynamic savedData = _box.get('upgrade_levels', defaultValue: {});
    
    final Map<String, int> levels = {};
    if (savedData is Map) {
      savedData.forEach((key, value) {
        if (key is String && value is int) {
          levels[key] = value;
        }
      });
    }

    return UpgradesState(levels: levels);
  }

  // Upgrade level'ı al
  int getLevel(String upgradeId) {
    return state.levels[upgradeId] ?? 0;
  }

  // Upgrade yap
  void upgradeItem(String upgradeId) {
    final currentLevel = getLevel(upgradeId);
    final newLevels = Map<String, int>.from(state.levels);
    newLevels[upgradeId] = currentLevel + 1;

    state = state.copyWith(levels: newLevels);
    _saveToHive();
  }

  // Hive'a kaydet
  void _saveToHive() {
    _box.put('upgrade_levels', state.levels);
  }

  // Test için sıfırla
  void resetUpgrades() {
    state = const UpgradesState(levels: {});
    _saveToHive();
  }
  
  // Tüm upgrade'leri sıfırla
  void resetAllUpgrades() {
    state = const UpgradesState(levels: {});
    _saveToHive();
  }
}

// Provider
final upgradesProvider = NotifierProvider<UpgradesNotifier, UpgradesState>(
  UpgradesNotifier.new,
);
