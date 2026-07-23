import 'package:equatable/equatable.dart';

import 'package:forja/domain/entities/achievement_entity.dart';

class AchievementsState extends Equatable {
  const AchievementsState({
    required this.achievements,
    this.newlyUnlocked = const [],
  });

  final List<AchievementEntity> achievements;
  final List<AchievementEntity> newlyUnlocked;

  @override
  List<Object?> get props => [achievements, newlyUnlocked];
}
