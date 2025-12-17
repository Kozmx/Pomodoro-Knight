import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/core/models/shop_item.dart';
import 'package:pomodoro_knight/logic/inventory/inventory_provider.dart';
import 'package:pomodoro_knight/logic/economy/economy_provider.dart';

class ItemCard extends ConsumerWidget {
  final ShopItem item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final isOwned =
        inventory.ownedWeapons.contains(item.id) ||
        inventory.ownedArmors.contains(item.id);
    final canAfford = ref.watch(
      economyProvider.select((state) => state.gold >= item.price),
    );

    return GestureDetector(
      onTap: isOwned
          ? null
          : () => _showItemDetails(context, ref, item, canAfford),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOwned
                ? Colors.green.withOpacity(0.5)
                : item.color.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Owned badge
              if (isOwned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'OWNED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const SizedBox(height: 2),

              // Item adı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  item.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),

              // Fiyat veya Owned
              Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: isOwned
                      ? Colors.green.withOpacity(0.2)
                      : const Color(0xFFFFD700).withOpacity(0.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (!isOwned) ...[
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.price}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showItemDetails(
  BuildContext context,
  WidgetRef ref,
  ShopItem item,
  bool canAfford,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with icon and name
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Color(0xFFFFD700),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.price}',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              item.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STATS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (item is WeaponItem) ...[
                    _buildStatRow(
                      Icons.flash_on,
                      'Damage',
                      '${item.damage}',
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      Icons.speed,
                      'Attack Speed',
                      '${item.attackSpeed}x',
                      Colors.orange,
                    ),
                  ] else if (item is ArmorItem) ...[
                    _buildStatRow(
                      Icons.shield,
                      'Defense',
                      '${item.defense}',
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      Icons.favorite,
                      'Health',
                      '+${item.health}',
                      Colors.pink,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buy Button
            ElevatedButton(
              onPressed: canAfford
                  ? () {
                      final success = ref
                          .read(inventoryProvider.notifier)
                          .purchaseItem(item, item.price);
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ ${item.name} satın alındı!'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? Colors.green : Colors.grey,
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                canAfford ? 'BUY NOW' : 'INSUFFICIENT GOLD',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Widget _buildStatRow(IconData icon, String label, String value, Color color) {
  return Row(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}
