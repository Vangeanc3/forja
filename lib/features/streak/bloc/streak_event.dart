import 'package:equatable/equatable.dart';

abstract class StreakEvent extends Equatable {
  const StreakEvent();

  @override
  List<Object?> get props => [];
}

class StreakRefreshed extends StreakEvent {
  const StreakRefreshed();
}

class StreakStarted extends StreakEvent {
  const StreakStarted();
}

class StreakRelapsed extends StreakEvent {
  const StreakRelapsed();
}
