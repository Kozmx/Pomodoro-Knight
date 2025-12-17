import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UpgradesState {
  final Map<String, int> levels;

  const UpgradesState({required this.levels});

  UpgradesState copyWith({Map<String, int>? levels}) {
    return UpgradesState(levels: levels ?? this.levels);
  }
}

class UpgradesNotifier extends Notifier<UpgradesState> {
  late Box _box;

  @override
  UpgradesState build() {
    _box = Hive.box('game_data');

    // Hive'dan upgrade level'ları yükle
    final Map<String, dynamic> savedLevels =
        _box.get('upgrade_levels', defaultValue: <String, dynamic>{})
            as Map<String, dynamic>;

    final Map<String, int> levels = savedLevels.map(
      (key, value) => MapEntry(key, value as int),
    );

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
}

// Provider
final upgradesProvider = NotifierProvider<UpgradesNotifier, UpgradesState>(
  UpgradesNotifier.new,
);
