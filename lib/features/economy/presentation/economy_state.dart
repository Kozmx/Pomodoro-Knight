class EconomyState {
  final int gold;

  const EconomyState({required this.gold});

  EconomyState copyWith({int? gold}) {
    return EconomyState(gold: gold ?? this.gold);
  }
}
