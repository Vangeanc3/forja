import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<HomeTabChanged>(_onTabChanged);
  }

  void _onTabChanged(HomeTabChanged event, Emitter<HomeState> emit) {
    emit(HomeState(selectedIndex: event.index));
  }
}
