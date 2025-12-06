import 'package:flutter/material.dart';
import '../models/upgrade_item.dart';

final List<UpgradeItem> mockUpgrades = [
  UpgradeItem(
    id: 'coin_boost',
    name: 'Coin Boost',
    description: 'Earn more coins from Pomodoro sessions',
    icon: Icons.monetization_on,
    color: const Color(0xFFFFD700),
    maxLevel: 5,
    basePrice: 200,
  ),
  UpgradeItem(
    id: 'damage_boost',
    name: 'Damage Boost',
    description: 'Increase all weapon damage',
    icon: Icons.flash_on,
    color: Colors.red,
    maxLevel: 10,
    basePrice: 300,
  ),
  UpgradeItem(
    id: 'defense_boost',
    name: 'Defense Boost',
    description: 'Increase all armor defense',
    icon: Icons.shield,
    color: Colors.blue,
    maxLevel: 10,
    basePrice: 300,
  ),
  UpgradeItem(
    id: 'health_boost',
    name: 'Health Boost',
    description: 'Increase maximum health',
    icon: Icons.favorite,
    color: Colors.pink,
    maxLevel: 8,
    basePrice: 250,
  ),
  UpgradeItem(
    id: 'speed_boost',
    name: 'Speed Boost',
    description: 'Increase attack speed',
    icon: Icons.speed,
    color: Colors.cyan,
    maxLevel: 5,
    basePrice: 400,
  ),
  UpgradeItem(
    id: 'crit_chance',
    name: 'Critical Hit',
    description: 'Increase critical hit chance',
    icon: Icons.star,
    color: Colors.amber,
    maxLevel: 5,
    basePrice: 500,
  ),
];
