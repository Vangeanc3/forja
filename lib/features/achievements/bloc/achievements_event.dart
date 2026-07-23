import 'package:equatable/equatable.dart';

abstract class AchievementsEvent extends Equatable {
  const AchievementsEvent();

  @override
  List<Object?> get props => [];
}

class AchievementsRefreshed extends AchievementsEvent {
  const AchievementsRefreshed();
}

class AchievementsChecked extends AchievementsEvent {
  const AchievementsChecked(this.currentDays);

  final int currentDays;

  @override
  List<Object?> get props => [currentDays];
}
