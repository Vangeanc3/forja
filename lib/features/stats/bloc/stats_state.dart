import 'package:equatable/equatable.dart';
import 'package:forja/domain/entities/stats_entity.dart';

class StatsState extends Equatable {
  const StatsState({required this.model});

  final StatsEntity model;

  @override
  List<Object?> get props => [
    model.bestStreak,
    model.totalCleanDays,
    model.totalRelapses,
    model.totalMissionsDone,
    model.memberSince,
    model.relapses,
  ];
}
