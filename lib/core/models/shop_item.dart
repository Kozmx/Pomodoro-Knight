import 'package:flutter/material.dart';

/// Silah tipi - melee (yakın) veya ranged (uzak menzilli)
enum WeaponType { melee, ranged }

abstract class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color color;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
  });
}

class WeaponItem extends ShopItem {
  final int damage;
  final double attackSpeed;
  final double critBonus;
  final String specialEffect;
  final WeaponType weaponType;
  final double? projectileSpeed; // Ranged silahlar için

  WeaponItem({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.icon,
    required super.color,
    required this.damage,
    required this.attackSpeed,
    this.critBonus = 0.0,
    this.specialEffect = 'None',
    this.weaponType = WeaponType.melee,
    this.projectileSpeed,
  });
}

class ArmorItem extends ShopItem {
  final int defense;
  final int health;

  ArmorItem({required super.id, required super.name, required super.description, required super.price, required super.icon, required super.color, required this.defense, required this.health});

}



