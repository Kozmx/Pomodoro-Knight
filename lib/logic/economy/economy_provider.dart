import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pomodoro_knight/core/constants/economy_constants.dart';
import 'package:pomodoro_knight/logic/economy/economy_state.dart';

class EconomyNotifier extends Notifier<EconomyState> {
  late Box _box;

  @override
  EconomyState build() {
    _box = Hive.box('game_data');
    final savedGold =
        _box.get('gold', defaultValue: EconomyConstants.initialGold) as int;

    return EconomyState(gold: savedGold);
  }

  // Altın ekle (Pomodoro kazancı)
  void addGold(int amount) {
    if (amount <= 0) return;

    final newGold = state.gold + amount;
    state = state.copyWith(gold: newGold);
    _saveToHive();
  }

  // Altın harca (Satın alma)
  bool spendGold(int amount) {
    if (amount <= 0) return false;
    if (state.gold < amount) return false; // Yetersiz bakiye

    final newGold = state.gold - amount;
    state = state.copyWith(gold: newGold);
    _saveToHive();
    return true;
  }

  // Satın alma kontrolü
  bool canAfford(int price) {
    return state.gold >= price;
  }

  // Hive'a kaydet
  void _saveToHive() {
    _box.put('gold', state.gold);
  }

  // Test için altın sıfırla
  void resetGold() {
    state = state.copyWith(gold: EconomyConstants.initialGold);
    _saveToHive();
  }

  // Test için belirli miktarda altın ayarla
  void setGoldForTesting(int amount) {
    state = state.copyWith(gold: amount);
    _saveToHive();
  }
}

// Provider
final economyProvider = NotifierProvider<EconomyNotifier, EconomyState>(
  EconomyNotifier.new,
);
