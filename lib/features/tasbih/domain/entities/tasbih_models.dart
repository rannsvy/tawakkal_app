class TasbihState {
  const TasbihState({
    required this.count,
    required this.target,
    required this.todayCycles,
  });

  final int count;
  final int target;
  final int todayCycles;

  TasbihState copyWith({int? count, int? target, int? todayCycles}) {
    return TasbihState(
      count: count ?? this.count,
      target: target ?? this.target,
      todayCycles: todayCycles ?? this.todayCycles,
    );
  }
}

class TasbihHistoryItem {
  const TasbihHistoryItem({
    required this.target,
    required this.finalCount,
    required this.completedAt,
  });

  final int target;
  final int finalCount;
  final DateTime completedAt;
}
