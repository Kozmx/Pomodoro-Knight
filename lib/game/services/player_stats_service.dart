/// Oyun içinden upgrade stat'larına erişmek için singleton servis
/// Provider'lar Flame game içinde direkt kullanılamadığı için
class PlayerStatsService {
  static final PlayerStatsService _instance = PlayerStatsService._internal();
  factory PlayerStatsService() => _instance;
  PlayerStatsService._internal();

  // Statlar (provider'dan güncellenecek)
  double attackSpeedMultiplier = 1.0;
  double damageMultiplier = 1.0;
  double maxHealthBonus = 0.0;
  double defenseMultiplier = 1.0;
  double coinMultiplier = 1.0;
  double criticalChance = 0.0;
  
  // Callback: Health upgrade alındığında player'ı güncellemek için
  Function(double oldMaxHealth, double newMaxHealth)? onMaxHealthChanged;

  /// Provider'dan statları güncelle
  void updateStats({
    required double attackSpeed,
    required double damage,
    required double maxHealth,
    required double defense,
    required double coin,
    required double crit,
  }) {
    final oldMaxHealth = maxHealthBonus;
    
    attackSpeedMultiplier = attackSpeed;
    damageMultiplier = damage;
    maxHealthBonus = maxHealth;
    defenseMultiplier = defense;
    coinMultiplier = coin;
    criticalChance = crit;
    
    // Health değişti mi kontrol et
    if (oldMaxHealth != maxHealth && onMaxHealthChanged != null) {
      onMaxHealthChanged!(oldMaxHealth, maxHealth);
    }
  }

  /// Debug bilgi
  @override
  String toString() {
    return '''
PlayerStats:
  Attack Speed: ${attackSpeedMultiplier.toStringAsFixed(2)}x
  Damage: ${damageMultiplier.toStringAsFixed(2)}x
  Max Health: +${maxHealthBonus.toInt()}
  Defense: ${defenseMultiplier.toStringAsFixed(2)}x
  Coin: ${coinMultiplier.toStringAsFixed(2)}x
  Crit: ${(criticalChance * 100).toStringAsFixed(1)}%
''';
  }
}
