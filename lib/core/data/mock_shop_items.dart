import 'package:flutter/material.dart';
import '../models/shop_item.dart';

// SILAHLAR
final List<WeaponItem> mockWeapons = [
  // Starter sword - şuan kullandığımız
  WeaponItem(
    id: 'weapon_starter',
    name: 'Knight Sword',
    description: 'A reliable starter blade',
    price: 0,
    icon: Icons.gavel,
    color: Colors.grey,
    damage: 10,
    attackSpeed: 1.0,
    critBonus: 0.0,
    specialEffect: 'None',
  ),
  WeaponItem(
    id: 'weapon_flame',
    name: 'Flame Blade',
    description: '+15% Crit Chance, Burns on hit',
    price: 350,
    icon: Icons.local_fire_department,
    color: Colors.orange,
    damage: 15,
    attackSpeed: 1.2,
    critBonus: 0.15,
    specialEffect: 'Burn: 3 dmg/sec for 2s',
  ),
  WeaponItem(
    id: 'weapon_frost',
    name: 'Frost Edge',
    description: '+10% Crit, Slows enemies',
    price: 400,
    icon: Icons.ac_unit,
    color: Colors.cyan,
    damage: 12,
    attackSpeed: 1.4,
    critBonus: 0.10,
    specialEffect: 'Slow: -30% enemy speed',
  ),
  WeaponItem(
    id: 'weapon_thunder',
    name: 'Thunder Axe',
    description: '+25% Crit, Chain lightning',
    price: 600,
    icon: Icons.bolt,
    color: Colors.yellow,
    damage: 20,
    attackSpeed: 0.9,
    critBonus: 0.25,
    specialEffect: 'Chain: Hits 2 nearby enemies',
  ),
];

// ZIRHLAR
final List<ArmorItem> mockArmors = [
  ArmorItem(
    id: 'armor_1',
    name: 'Leather Armor',
    description: 'Light protection for starters',
    price: 80,
    icon: Icons.shield,
    color: Colors.brown,
    defense: 5,
    health: 20,
  ),
  ArmorItem(
    id: 'armor_2',
    name: 'Iron Armor',
    description: 'Solid iron protection',
    price: 200,
    icon: Icons.security,
    color: Colors.grey,
    defense: 15,
    health: 50,
  ),
  ArmorItem(
    id: 'armor_3',
    name: 'Dragon Scale Armor',
    description: 'Made from real dragon scales',
    price: 600,
    icon: Icons.shield_outlined,
    color: Colors.red,
    defense: 30,
    health: 100,
  ),
  ArmorItem(
    id: 'armor_4',
    name: 'Steel Armor',
    description: 'Enhanced steel plates',
    price: 400,
    icon: Icons.shield_outlined,
    color: Colors.blueGrey,
    defense: 25,
    health: 80,
  ),
  ArmorItem(
    id: 'armor_5',
    name: 'Dragon Scale',
    description: 'Made from real dragon scales',
    price: 900,
    icon: Icons.crisis_alert,
    color: Colors.red,
    defense: 40,
    health: 120,
  ),
  ArmorItem(
    id: 'armor_6',
    name: 'Divine Armor',
    description: 'Blessed by the gods',
    price: 2000,
    icon: Icons.favorite,
    color: Colors.purple,
    defense: 70,
    health: 200,
  ),
];

// TÜM İTEMLER (gerekirse)
final List<ShopItem> allShopItems = [...mockWeapons, ...mockArmors];
