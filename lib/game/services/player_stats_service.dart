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
  
  // Equipped weapon stats
  String? equippedWeaponId;
  int weaponBaseDamage = 10;
  double weaponAttackSpeed = 1.0;
  double weaponCritBonus = 0.0;
  String weaponSpecialEffect = 'None';
  
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

  /// Equipped weapon'ı güncelle
  void updateEquippedWeapon({
    required String? weaponId,
    required int baseDamage,
    required double attackSpeed,
    required double critBonus,
    required String specialEffect,
  }) {
    equippedWeaponId = weaponId;
    weaponBaseDamage = baseDamage;
    weaponAttackSpeed = attackSpeed;
    weaponCritBonus = critBonus;
    weaponSpecialEffect = specialEffect;
  }
  
  /// Toplam crit chance (upgrade + weapon)
  double get totalCritChance => criticalChance + weaponCritBonus;
  
  /// Toplam attack speed (upgrade * weapon)
  double get totalAttackSpeed => attackSpeedMultiplier * weaponAttackSpeed;
  
  /// Toplam base damage
  double get totalBaseDamage => weaponBaseDamage * damageMultiplier;

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
  Weapon: $equippedWeaponId (DMG:$weaponBaseDamage, SPD:$weaponAttackSpeed, CRIT:+${(weaponCritBonus*100).toInt()}%)
''';
  }
}
