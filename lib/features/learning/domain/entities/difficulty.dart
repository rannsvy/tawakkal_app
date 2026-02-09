enum Difficulty {
  easy,
  medium,
  hard;

  static Difficulty fromKey(String key) {
    return Difficulty.values.firstWhere(
      (difficulty) => difficulty.name == key,
      orElse: () => Difficulty.easy,
    );
  }
}
