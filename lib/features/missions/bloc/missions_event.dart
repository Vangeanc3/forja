import 'package:equatable/equatable.dart';

abstract class MissionsEvent extends Equatable {
  const MissionsEvent();

  @override
  List<Object?> get props => [];
}

class MissionsRefreshed extends MissionsEvent {
  const MissionsRefreshed();
}

class MissionToggled extends MissionsEvent {
  const MissionToggled(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
