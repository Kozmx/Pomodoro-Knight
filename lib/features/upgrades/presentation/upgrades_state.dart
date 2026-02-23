class UpgradesState {
  final Map<String, int> levels;

  const UpgradesState({required this.levels});

  UpgradesState copyWith({Map<String, int>? levels}) {
    return UpgradesState(levels: levels ?? this.levels);
  }

  // Level getter
  int getLevel(String upgradeId) => levels[upgradeId] ?? 0;

  // Stat hesaplamaları
  
  /// Saldırı hızı çarpanı (speed_boost)
  /// Her level %20 hız artışı
  double get attackSpeedMultiplier {
    final level = getLevel('speed_boost');
    return 1.0 + (level * 0.20); // 1.0, 1.2, 1.4, 1.6, 1.8, 2.0
  }

  /// Hasar çarpanı (damage_boost)
  /// Her level %15 hasar artışı
  double get damageMultiplier {
    final level = getLevel('damage_boost');
    return 1.0 + (level * 0.15);
  }

  /// Maksimum can bonusu (health_boost)
  /// Her level +25 can
  double get maxHealthBonus {
    final level = getLevel('health_boost');
    return level * 25.0;
  }

  /// Savunma çarpanı (defense_boost)
  /// Her level %8 hasar azaltma
  double get defenseMultiplier {
    final level = getLevel('defense_boost');
    final reduction = (level * 0.08).clamp(0.0, 0.6); // Max %60 azaltma
    return 1.0 - reduction;
  }

  /// Coin bonusu (coin_boost)
  /// Her level %10 daha fazla coin
  double get coinMultiplier {
    final level = getLevel('coin_boost');
    return 1.0 + (level * 0.10);
  }

  /// Kritik şans (crit_chance)
  /// Her level %5 kritik şans
  double get criticalChance {
    final level = getLevel('crit_chance');
    return (level * 0.05).clamp(0.0, 0.25); // Max %25
  }
}
