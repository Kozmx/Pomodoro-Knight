import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/features/shop/domain/shop_item.dart';
import 'package:pomodoro_knight/features/inventory/presentation/inventory_state.dart';
import 'package:pomodoro_knight/features/auth/presentation/user_provider.dart';
import 'package:pomodoro_knight/features/auth/presentation/auth_provider.dart';

// Envanter ve kuşanma işlemlerini yöneten Notifier
class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() {
    // Firestore'dan gelen kullanıcı verisini canlı olarak izler
    final userAsync = ref.watch(userProvider);

    // Kullanıcı verisi değiştikçe envanter durumunu günceller
    return userAsync.maybeWhen(
      data: (user) {
        if (user == null) return const InventoryState();

        return InventoryState(
          // 'weapon_' ile başlayan ID'leri silah listesine ayırır
          ownedWeapons: user.ownedItems
              .where((id) => id.startsWith('weapon_'))
              .toList(),
          // 'armor_' ile başlayan ID'leri zırh listesine ayırır
          ownedArmors: user.ownedItems
              .where((id) => id.startsWith('armor_'))
              .toList(),
          equippedWeapon: user.equipment.equippedWeaponId,
          equippedArmor: user.equipment.equippedArmorId,
        );
      },
      orElse: () => const InventoryState(),
    );
  }

  // Eşya satın alma işlemini başlatır (Firestore Transaction kullanır)
  Future<bool> purchaseItem(ShopItem item, int price) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return false;

    final repo = ref.read(userRepositoryProvider);
    // Repository üzerinden güvenli satın alma işlemini tetikler
    return await repo.purchaseItem(user.uid, price, item.id);
  }

  // Silah kuşanma işlemini Firestore'da günceller
  Future<void> equipWeapon(String weaponId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final repo = ref.read(userRepositoryProvider);
    // Mevcut zırh bilgisini koruyarak sadece silahı günceller
    await repo.updateEquipment(user.uid, weaponId, state.equippedArmor);
  }

  // Zırh kuşanma işlemini Firestore'da günceller
  Future<void> equipArmor(String armorId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final repo = ref.read(userRepositoryProvider);
    // Mevcut silah bilgisini koruyarak sadece zırhı günceller
    await repo.updateEquipment(user.uid, state.equippedWeapon, armorId);
  }

  // Yardımcı metot: Belirli bir eşyaya sahip miyiz kontrolü
  bool hasItem(String itemId) {
    return state.ownedWeapons.contains(itemId) ||
        state.ownedArmors.contains(itemId);
  }
}

// Uygulama genelinde kullanılacak envanter provider'ı
final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(
  InventoryNotifier.new,
);
