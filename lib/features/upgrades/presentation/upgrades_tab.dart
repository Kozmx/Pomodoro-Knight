import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/features/upgrades/data/mock_upgrades.dart';
import 'package:pomodoro_knight/features/upgrades/presentation/widgets/upgrade_card.dart';
import 'package:pomodoro_knight/features/upgrades/presentation/upgrades_provider.dart';
import 'package:pomodoro_knight/features/auth/presentation/user_provider.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';

class UpgradesTab extends ConsumerWidget {
  const UpgradesTab({super.key});

  // Geliştirme butonuna basıldığında çalışan işlem
  void _handleUpgrade(
    BuildContext context,
    WidgetRef ref,
    String upgradeId,
    int price,
    int maxLevel,
    int currentLevel,
  ) async {
    // 1. Max level kontrolü
    if (currentLevel >= maxLevel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Already at max level!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 2. Altın kontrolü (Firestore'dan gelen güncel bakiye)
    final gold = ref.read(userGoldProvider);
    if (gold < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Insufficient gold!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 3. Firestore İşlemi: Altını düş ve seviyeyi artır
    final success = await ref
        .read(upgradesProvider.notifier)
        .upgradeItem(upgradeId, price);

    if (success) {
      // Başarılı olursa ses çal ve mesaj göster
      GameAudioService().playPurchase();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Upgrade successful! -$price gold'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Firestore işleminde hata oluşursa
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error processing upgrade. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Geliştirme seviyelerini ve altın miktarını Firestore'dan izliyoruz
    final upgradesState = ref.watch(upgradesProvider);
    final gold = ref.watch(userGoldProvider);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Başlık ve açıklama alanı
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERMANENT UPGRADES',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enhance your knight with permanent stat boosts',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),

        // Geliştirme kartlarının listelendiği alan
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final upgrade = mockUpgrades[index];
              final currentLevel = upgradesState.levels[upgrade.id] ?? 0;
              final price = upgrade.getPriceForLevel(currentLevel);
              final canAfford = gold >= price;

              return UpgradeCard(
                upgrade: upgrade,
                currentLevel: currentLevel,
                canAfford: canAfford,
                onUpgrade: () => _handleUpgrade(
                  context,
                  ref,
                  upgrade.id,
                  price,
                  upgrade.maxLevel,
                  currentLevel,
                ),
              );
            }, childCount: mockUpgrades.length),
          ),
        ),

        // Alt boşluk
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }
}
