class UpgradesState {
  final Map<String, int> levels;

  const UpgradesState({required this.levels});

  UpgradesState copyWith({Map<String, int>? levels}) {
    return UpgradesState(levels: levels ?? this.levels);
  }
}
