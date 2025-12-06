import 'package:flutter/material.dart';
import 'package:pomodoro_knight/core/models/shop_item.dart';

class ItemCard extends StatelessWidget {
  final ShopItem item;
  final VoidCallback? onTap;

  const ItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.color.withOpacity(0.5), width: 2),
        ),
        child: Column(
        
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 32),
            ),
            const SizedBox(height: 12),

            // Item adı (opsiyonel - kaldırabilirsin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Fiyat
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
