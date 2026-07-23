import 'package:equatable/equatable.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

class StatsRefreshed extends StatsEvent {
  const StatsRefreshed();
}

class StatsRelapseRecorded extends StatsEvent {
  const StatsRelapseRecorded(this.currentStreak);

  final int currentStreak;

  @override
  List<Object?> get props => [currentStreak];
}

class StatsMissionCompleted extends StatsEvent {
  const StatsMissionCompleted();
}

class StatsMemberSinceSet extends StatsEvent {
  const StatsMemberSinceSet(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}
