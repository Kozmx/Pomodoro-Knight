import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_knight/game/enemy/slime/slime.dart';
import 'package:pomodoro_knight/game/enemy/slime/bat.dart';
import 'package:pomodoro_knight/game/enemy/flower/flower.dart';
import 'package:pomodoro_knight/game/enemy/boss/boss_base.dart';
import 'package:pomodoro_knight/game/components/damage_text.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';
import 'package:pomodoro_knight/game/services/player_stats_service.dart';

class Weapon extends PositionComponent with CollisionCallbacks {
  final GameAudioService _audioService = GameAudioService();
  final PlayerStatsService _statsService = PlayerStatsService();
  final Random _random = Random();

  Weapon({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
    
    // Silah rengini equipped weapon'a göre ayarla
    Color weaponColor;
    final weaponId = _statsService.equippedWeaponId;
    if (weaponId == 'weapon_flame') {
      weaponColor = Colors.orange.withOpacity(0.7);
    } else if (weaponId == 'weapon_frost') {
      weaponColor = Colors.cyan.withOpacity(0.7);
    } else if (weaponId == 'weapon_thunder') {
      weaponColor = Colors.yellow.withOpacity(0.7);
    } else {
      weaponColor = Colors.grey.withOpacity(0.5);
    }
    
    add(RectangleComponent(size: size, paint: Paint()..color = weaponColor));

    // Remove after 0.2 seconds (attack speed'e göre ayarlanabilir)
    final duration = (200 / _statsService.totalAttackSpeed).toInt();
    Future.delayed(Duration(milliseconds: duration), () {
      removeFromParent();
    });
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    
    // Toplam base damage (weapon + upgrade multiplier)
    final baseDamage = _statsService.totalBaseDamage;
    
    // Crit kontrolü (upgrade + weapon crit bonus)
    final critChance = _statsService.totalCritChance;
    final isCritical = _random.nextDouble() < critChance;
    
    // Final hasar
    final damage = isCritical ? baseDamage * 2 : baseDamage;

    bool hitEnemy = false;

    if (other is Enemy) {
      other.takeDamage(damage);
      _showDamageText(other.position, damage, isCritical);
      hitEnemy = true;
    } else if (other is FlyingEnemy) {
      other.takeDamage(damage);
      _showDamageText(other.position, damage, isCritical);
      hitEnemy = true;
    } else if (other is FlowerEnemy) {
      other.takeDamage(damage);
      _showDamageText(other.position, damage, isCritical);
      hitEnemy = true;
    } else if (other is BossBase) {
      other.takeDamage(damage);
      _showDamageText(other.position, damage, isCritical);
      hitEnemy = true;
    }

    // Düşmana vurduğunda vuruş sesi çal
    if (hitEnemy) {
      _audioService.playSwordHit();
    }
  }

  void _showDamageText(Vector2 enemyPosition, double damage, bool isCritical) {
    final damageText = DamageText(
      position: enemyPosition.clone() + Vector2(0, -40),
      damage: damage,
      isCritical: isCritical,
    );
    parent?.add(damageText);
  }
}
