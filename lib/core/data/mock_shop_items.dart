import 'package:flutter/material.dart';
import '../models/shop_item.dart';

// SILAHLAR
final List<WeaponItem> mockWeapons = [
  
  WeaponItem(
    id: 'weapon_3',
    name: 'Fire Blade',
    description: 'Burns enemies on hit',
    price: 500,
    icon: Icons.local_fire_department,
    color: Colors.orange,
    damage: 35,
    attackSpeed: 1.5,
  ),
  WeaponItem(
    id: 'weapon_4',
    name: 'Ice Dagger',
    description: 'Freezes enemies',
    price: 450,
    icon: Icons.ac_unit,
    color: Colors.cyan,
    damage: 30,
    attackSpeed: 1.8,
  ),
  WeaponItem(
    id: 'weapon_5',
    name: 'Thunder Axe',
    description: 'Strikes with lightning',
    price: 800,
    icon: Icons.bolt,
    color: Colors.yellow,
    damage: 45,
    attackSpeed: 1.3,
  ),
  WeaponItem(
    id: 'weapon_6',
    name: 'Excalibur',
    description: 'The legendary sword',
    price: 1500,
    icon: Icons.auto_awesome,
    color: Colors.amber,
    damage: 60,
    attackSpeed: 2.0,
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
