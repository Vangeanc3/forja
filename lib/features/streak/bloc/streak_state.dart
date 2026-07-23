import 'package:equatable/equatable.dart';
import 'package:forja/domain/entities/streak_entity.dart';

class StreakState extends Equatable {
  const StreakState({required this.streak});

  final StreakEntity streak;

  int get days => streak.currentDays;

  @override
  List<Object?> get props => [streak.currentDays, streak.startedAt];
}
