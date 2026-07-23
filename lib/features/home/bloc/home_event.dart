import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeTabChanged extends HomeEvent {
  const HomeTabChanged(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}
