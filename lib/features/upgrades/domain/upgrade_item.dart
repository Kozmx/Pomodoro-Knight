import 'package:flutter/material.dart';

class UpgradeItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int maxLevel;
  final int basePrice;

  UpgradeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.maxLevel,
    required this.basePrice,
  });

  // Level'e göre fiyat hesapla (her level daha pahalı)
  int getPriceForLevel(int currentLevel) {
    return basePrice * (currentLevel + 1);
  }

  // Bonus değeri hesapla
  String getBonusText(int level) {
    switch (id) {
      case 'coin_boost':
        return '+${level * 10}% Coins';
      case 'damage_boost':
        return '+${level * 5} Damage';
      case 'defense_boost':
        return '+${level * 5} Defense';
      case 'health_boost':
        return '+${level * 20} Health';
      case 'speed_boost':
        return '+${level * 0.1}x Attack Speed';
      default:
        return 'Level $level';
    }
  }
}
