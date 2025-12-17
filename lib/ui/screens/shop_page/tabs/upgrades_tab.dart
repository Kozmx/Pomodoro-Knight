import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/core/data/mock_upgrades.dart';
import 'package:pomodoro_knight/ui/screens/shop_page/widgets/upgrade_card.dart';
import 'package:pomodoro_knight/logic/upgrades/upgrades_provider.dart';
import 'package:pomodoro_knight/logic/economy/economy_provider.dart';

class UpgradesTab extends ConsumerWidget {
  const UpgradesTab({super.key});

  void _handleUpgrade(
    BuildContext context,
    WidgetRef ref,
    String upgradeId,
    int price,
    int maxLevel,
    int currentLevel,
  ) {
    // Max level kontrolü
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

    // Gold kontrolü
    final canAfford = ref.read(economyProvider).gold >= price;
    if (!canAfford) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Insufficient gold!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Gold harca
    final success = ref.read(economyProvider.notifier).spendGold(price);
    if (success) {
      // Upgrade yap
      ref.read(upgradesProvider.notifier).upgradeItem(upgradeId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Upgrade successful! -$price gold'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upgradesState = ref.watch(upgradesProvider);
    final gold = ref.watch(economyProvider).gold;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Başlık ve açıklama
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

        // Upgrade kartları
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final upgrade = mockUpgrades[index];
              final currentLevel = upgradesState.levels[upgrade.id] ?? 0;
              final canAfford = gold >= upgrade.getPriceForLevel(currentLevel);

              return UpgradeCard(
                upgrade: upgrade,
                currentLevel: currentLevel,
                canAfford: canAfford,
                onUpgrade: () => _handleUpgrade(
                  context,
                  ref,
                  upgrade.id,
                  upgrade.getPriceForLevel(currentLevel),
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
