import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pomodoro_knight/core/models/shop_item.dart';
import 'package:pomodoro_knight/logic/economy/economy_provider.dart';
import 'package:pomodoro_knight/logic/inventory/inventory_state.dart';

class InventoryNotifier extends Notifier<InventoryState> {
  late Box _box;

  @override
  InventoryState build() {
    _box = Hive.box('game_data');

    final List<String> weapons =
        (_box.get('owned_weapons', defaultValue: []) as List).cast<String>();
    final List<String> armors =
        (_box.get('owned_armors', defaultValue: []) as List).cast<String>();
    final String? equippedWeapon = _box.get('equipped_weapon') as String?;
    final String? equippedArmor = _box.get('equipped_armor') as String?;

    return InventoryState(
      ownedWeapons: weapons,
      ownedArmors: armors,
      equippedWeapon: equippedWeapon,
      equippedArmor: equippedArmor,
    );
  }

  // Silah veya zırh satın al
  bool purchaseItem(ShopItem item, int price) {
    // Zaten sahip mi kontrol et
    if (hasItem(item.id)) {
      return false; // Zaten satın alınmış
    }

    // Yeterli gold var mı kontrol et ve harca
    final success = ref.read(economyProvider.notifier).spendGold(price);
    if (!success) {
      return false; // Yetersiz bakiye
    }

    // Item'ı envantere ekle
    if (item is WeaponItem) {
      final newWeapons = List<String>.from(state.ownedWeapons)..add(item.id);
      state = state.copyWith(ownedWeapons: newWeapons);
      _box.put('owned_weapons', newWeapons);

      // İlk silahsa otomatik kuşan
      if (state.equippedWeapon == null) {
        equipWeapon(item.id);
      }
    } else if (item is ArmorItem) {
      final newArmors = List<String>.from(state.ownedArmors)..add(item.id);
      state = state.copyWith(ownedArmors: newArmors);
      _box.put('owned_armors', newArmors);

      // İlk zırhsa otomatik kuşan
      if (state.equippedArmor == null) {
        equipArmor(item.id);
      }
    }

    return true;
  }

  // Item sahipliği kontrolü
  bool hasItem(String itemId) {
    return state.ownedWeapons.contains(itemId) ||
        state.ownedArmors.contains(itemId);
  }

  // Silah kuşan
  void equipWeapon(String weaponId) {
    if (!state.ownedWeapons.contains(weaponId)) return;

    state = state.copyWith(equippedWeapon: weaponId);
    _box.put('equipped_weapon', weaponId);
  }

  // Zırh kuşan
  void equipArmor(String armorId) {
    if (!state.ownedArmors.contains(armorId)) return;

    state = state.copyWith(equippedArmor: armorId);
    _box.put('equipped_armor', armorId);
  }

  // Test için sıfırla
  void reset() {
    state = const InventoryState();
    _box.delete('owned_weapons');
    _box.delete('owned_armors');
    _box.delete('equipped_weapon');
    _box.delete('equipped_armor');
  }
}

// Provider
final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(
  InventoryNotifier.new,
);
