import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  const HomeState({this.selectedIndex = 0});

  final int selectedIndex;

  @override
  List<Object?> get props => [selectedIndex];
}
