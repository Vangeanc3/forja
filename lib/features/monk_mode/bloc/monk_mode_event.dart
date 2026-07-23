import 'package:equatable/equatable.dart';

abstract class MonkModeEvent extends Equatable {
  const MonkModeEvent();

  @override
  List<Object?> get props => [];
}

class MonkModeRefreshed extends MonkModeEvent {
  const MonkModeRefreshed();
}

class MonkModeSaved extends MonkModeEvent {
  const MonkModeSaved({required this.active, required this.restrictions});

  final bool active;
  final List<String> restrictions;

  @override
  List<Object?> get props => [active, restrictions];
}
