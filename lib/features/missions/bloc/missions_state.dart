import 'package:equatable/equatable.dart';

import 'package:forja/domain/entities/mission_entity.dart';

class MissionsState extends Equatable {
  const MissionsState({required this.missions});

  final List<MissionEntity> missions;

  @override
  List<Object?> get props => [missions];
}
