import 'package:equatable/equatable.dart';

class ProgressSnapshot extends Equatable {
  const ProgressSnapshot({
    required this.xpTotal,
    required this.currentStreak,
    required this.longestStreak,
    required this.level,
  });

  final int xpTotal;
  final int currentStreak;
  final int longestStreak;
  final int level;

  @override
  List<Object?> get props => [xpTotal, currentStreak, longestStreak, level];
}
