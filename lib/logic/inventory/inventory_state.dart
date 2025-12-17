class InventoryState {
  final List<String> ownedWeapons;
  final List<String> ownedArmors;
  final String? equippedWeapon;
  final String? equippedArmor;

  const InventoryState({
    this.ownedWeapons = const [],
    this.ownedArmors = const [],
    this.equippedWeapon,
    this.equippedArmor,
  });

  InventoryState copyWith({
    List<String>? ownedWeapons,
    List<String>? ownedArmors,
    String? equippedWeapon,
    String? equippedArmor,
    bool clearEquippedWeapon = false,
    bool clearEquippedArmor = false,
  }) {
    return InventoryState(
      ownedWeapons: ownedWeapons ?? this.ownedWeapons,
      ownedArmors: ownedArmors ?? this.ownedArmors,
      equippedWeapon: clearEquippedWeapon
          ? null
          : (equippedWeapon ?? this.equippedWeapon),
      equippedArmor: clearEquippedArmor
          ? null
          : (equippedArmor ?? this.equippedArmor),
    );
  }
}
