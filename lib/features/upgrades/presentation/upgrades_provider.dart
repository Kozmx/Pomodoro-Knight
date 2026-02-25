import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/features/upgrades/presentation/upgrades_state.dart';
import 'package:pomodoro_knight/features/auth/presentation/user_provider.dart';
import 'package:pomodoro_knight/features/auth/presentation/auth_provider.dart';

// Geliştirme (Upgrade) seviyelerini yöneten Notifier
class UpgradesNotifier extends Notifier<UpgradesState> {
  @override
  UpgradesState build() {
    // Firestore'dan gelen kullanıcı verisini canlı olarak izler
    final userAsync = ref.watch(userProvider);

    // Veri geldiğinde geliştirme seviyelerini otomatik günceller
    return userAsync.maybeWhen(
      data: (user) {
        if (user == null) return const UpgradesState(levels: {});
        return UpgradesState(levels: user.upgradeLevels);
      },
      orElse: () => const UpgradesState(levels: {}),
    );
  }

  // Belirli bir geliştirmenin seviyesini döndürür
  int getLevel(String upgradeId) {
    return state.levels[upgradeId] ?? 0;
  }

  // Geliştirme yapma işlemini başlatır (Firestore Transaction kullanır)
  Future<bool> upgradeItem(String upgradeId, int price) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return false;

    final repo = ref.read(userRepositoryProvider);
    // Firestore'da altın düşüp seviyeyi artıran güvenli işlemi tetikler
    return await repo.upgradeStat(user.uid, price, upgradeId);
  }

  // Boş metodlar (Firestore yapısında resetleme işlemi repository üzerinden yapılmalı)
  void resetUpgrades() {}
  void resetAllUpgrades() {}
}

// Uygulama genelinde kullanılacak geliştirmeler provider'ı
final upgradesProvider = NotifierProvider<UpgradesNotifier, UpgradesState>(
  UpgradesNotifier.new,
);
