import 'package:equatable/equatable.dart';

enum RewardMilestoneKind { streak, xp, tasbih, quiz }

class RewardMilestone extends Equatable {
  const RewardMilestone({
    required this.code,
    required this.title,
    required this.description,
    required this.kind,
    required this.currentValue,
    required this.threshold,
    required this.unitLabel,
  });

  final String code;
  final String title;
  final String description;
  final RewardMilestoneKind kind;
  final int currentValue;
  final int threshold;
  final String unitLabel;

  bool get isUnlocked => currentValue >= threshold;

  double get progress {
    if (threshold <= 0) {
      return 1;
    }
    return (currentValue / threshold).clamp(0, 1).toDouble();
  }

  String get progressText => '$currentValue/$threshold $unitLabel';

  @override
  List<Object?> get props => [
    code,
    title,
    description,
    kind,
    currentValue,
    threshold,
    unitLabel,
  ];
}
