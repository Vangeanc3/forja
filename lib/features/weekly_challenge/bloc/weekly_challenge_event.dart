import 'package:equatable/equatable.dart';

abstract class WeeklyChallengeEvent extends Equatable {
  const WeeklyChallengeEvent();

  @override
  List<Object?> get props => [];
}

class WeeklyChallengeRefreshed extends WeeklyChallengeEvent {
  const WeeklyChallengeRefreshed();
}

class WeeklyChallengeAcceptanceChanged extends WeeklyChallengeEvent {
  const WeeklyChallengeAcceptanceChanged(this.accepted);

  final bool accepted;

  @override
  List<Object?> get props => [accepted];
}
