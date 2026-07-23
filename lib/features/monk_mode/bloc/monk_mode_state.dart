import 'package:equatable/equatable.dart';
import 'package:forja/domain/entities/monk_mode_entity.dart';

class MonkModeState extends Equatable {
  const MonkModeState({required this.active, required this.restrictions});

  factory MonkModeState.fromEntity(MonkModeEntity entity) =>
      MonkModeState(active: entity.active, restrictions: entity.restrictions);

  final bool active;
  final List<String> restrictions;

  @override
  List<Object?> get props => [active, restrictions];
}
