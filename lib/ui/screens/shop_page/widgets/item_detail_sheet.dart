import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/core/models/shop_item.dart';

class ItemDetailSheet extends ConsumerWidget {
  final ShopItem item;

  const ItemDetailSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst çizgi (kaydırma handle)
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: item.color, width: 3),
            ),
            child: Icon(item.icon, color: item.color, size: 50),
          ),
          const SizedBox(height: 16),

          // Item adı
          Text(
            item.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Açıklama
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          // Özellikler
          _buildStats(),
          const SizedBox(height: 24),

          // Fiyat ve Satın Al Butonu - Tek Buton
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Satın alma işlemi
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} purchased!'),
                    backgroundColor: item.color,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: item.color,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.price}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 2,
                    height: 24,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'BUY',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (item is WeaponItem) {
      final weapon = item as WeaponItem;
      return Column(
        children: [
          _buildStatRow(Icons.flash_on, 'Damage', '${weapon.damage}'),
          const SizedBox(height: 8),
          _buildStatRow(Icons.speed, 'Attack Speed', '${weapon.attackSpeed}x'),
        ],
      );
    } else if (item is ArmorItem) {
      final armor = item as ArmorItem;
      return Column(
        children: [
          _buildStatRow(Icons.shield, 'Defense', '${armor.defense}'),
          const SizedBox(height: 8),
          _buildStatRow(Icons.favorite, 'Health', '+${armor.health}'),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: item.color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }
}
