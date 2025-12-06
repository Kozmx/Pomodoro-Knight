import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/core/data/mock_upgrades.dart';
import 'package:pomodoro_knight/ui/screens/shop_page/widgets/upgrade_card.dart';

class UpgradesTab extends ConsumerStatefulWidget {
  const UpgradesTab({super.key});

  @override
  ConsumerState<UpgradesTab> createState() => _UpgradesTabState();
}

class _UpgradesTabState extends ConsumerState<UpgradesTab> {
  // Geçici olarak level'ları tutuyoruz (sonra provider'a taşınacak)
  final Map<String, int> _upgradeLevels = {
    'coin_boost': 2,
    'damage_boost': 0,
    'defense_boost': 1,
    'health_boost': 0,
    'speed_boost': 0,
    'crit_chance': 0,
  };

  void _handleUpgrade(String upgradeId, int price) {
    // TODO: Coin kontrolü yapılacak (shop provider'dan)
    setState(() {
      _upgradeLevels[upgradeId] = (_upgradeLevels[upgradeId] ?? 0) + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upgrade successful! -$price coins'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              final currentLevel = _upgradeLevels[upgrade.id] ?? 0;

              return UpgradeCard(
                upgrade: upgrade,
                currentLevel: currentLevel,
                onUpgrade: () => _handleUpgrade(
                  upgrade.id,
                  upgrade.getPriceForLevel(currentLevel),
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
