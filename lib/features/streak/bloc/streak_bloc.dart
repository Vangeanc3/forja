import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/streak_repository.dart';
import 'streak_event.dart';
import 'streak_state.dart';

class StreakBloc extends Bloc<StreakEvent, StreakState> {
  StreakBloc(this._repository)
    : super(StreakState(streak: _repository.snapshot())) {
    on<StreakRefreshed>(_onRefreshed);
    on<StreakStarted>(_onStarted);
    on<StreakRelapsed>(_onRelapsed);
  }

  final StreakRepository _repository;

  void _onRefreshed(StreakRefreshed event, Emitter<StreakState> emit) {
    emit(StreakState(streak: _repository.snapshot()));
  }

  Future<void> _onStarted(
    StreakStarted event,
    Emitter<StreakState> emit,
  ) async {
    await _repository.startStreak();
    emit(StreakState(streak: _repository.snapshot()));
  }

  Future<void> _onRelapsed(
    StreakRelapsed event,
    Emitter<StreakState> emit,
  ) async {
    await _repository.resetStreak();
    await _repository.startStreak();
    emit(StreakState(streak: _repository.snapshot()));
  }
}
