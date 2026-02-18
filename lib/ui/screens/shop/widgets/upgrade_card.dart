import 'package:flutter/material.dart';
import 'package:pomodoro_knight/core/models/upgrade_item.dart';

class UpgradeCard extends StatelessWidget {
  final UpgradeItem upgrade;
  final int currentLevel;
  final bool canAfford;
  final VoidCallback? onUpgrade;

  const UpgradeCard({
    super.key,
    required this.upgrade,
    required this.currentLevel,
    required this.canAfford,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isMaxLevel = currentLevel >= upgrade.maxLevel;
    final nextPrice = upgrade.getPriceForLevel(currentLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: upgrade.color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: upgrade.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(upgrade.icon, color: upgrade.color, size: 28),
              ),
              const SizedBox(width: 16),

              // Başlık ve seviye
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upgrade.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMaxLevel
                          ? 'MAX LEVEL'
                          : 'Level $currentLevel/${upgrade.maxLevel}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isMaxLevel ? Colors.amber : Colors.grey[400],
                        fontWeight: isMaxLevel
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // Current bonus badge
              if (currentLevel > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: upgrade.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: upgrade.color, width: 1),
                  ),
                  child: Text(
                    upgrade.getBonusText(currentLevel),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: upgrade.color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Açıklama
          Text(
            upgrade.description,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: currentLevel / upgrade.maxLevel,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(upgrade.color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '$currentLevel / ${upgrade.maxLevel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: upgrade.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isMaxLevel || !canAfford) ? null : onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: isMaxLevel
                    ? Colors.grey[800]
                    : canAfford
                    ? upgrade.color
                    : Colors.grey[700],
                disabledBackgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isMaxLevel
                  ? const Text(
                      'MAX LEVEL REACHED',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    )
                  : !canAfford
                  ? const Text(
                      'INSUFFICIENT GOLD',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Color(0xFFFFD700),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$nextPrice',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'UPGRADE',
                          style: TextStyle(
                            fontSize: 16,
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
}
