// Oyuncu temel istatistikleri ve yükseltme bonusları
class GameConstants {
  // Temel oyuncu istatistikleri
  static const int basePlayerDamage = 10;
  static const int basePlayerDefense = 0;
  static const int basePlayerHealth = 100;
  static const double baseAttackSpeed = 1.0;

  // Yükseltme bonusları (seviye başına)
  static const int damageBoostPerLevel = 5;
  static const int defenseBoostPerLevel = 5;
  static const int healthBoostPerLevel = 20;
  static const double speedBoostPerLevel = 0.1;
  static const int critChancePerLevel = 5; // %5 per level
}
