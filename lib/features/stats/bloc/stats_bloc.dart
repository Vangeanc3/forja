import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/stats_repository.dart';
import 'stats_event.dart';
import 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  StatsBloc(this._repository)
    : super(StatsState(model: _repository.buildModel())) {
    on<StatsRefreshed>(_onRefreshed);
    on<StatsRelapseRecorded>(_onRelapseRecorded);
    on<StatsMissionCompleted>(_onMissionCompleted);
    on<StatsMemberSinceSet>(_onMemberSinceSet);
  }

  final StatsRepository _repository;

  void _onRefreshed(StatsRefreshed event, Emitter<StatsState> emit) {
    emit(StatsState(model: _repository.buildModel()));
  }

  Future<void> _onRelapseRecorded(
    StatsRelapseRecorded event,
    Emitter<StatsState> emit,
  ) async {
    await _repository.recordRelapse(event.currentStreak);
    emit(StatsState(model: _repository.buildModel()));
  }

  Future<void> _onMissionCompleted(
    StatsMissionCompleted event,
    Emitter<StatsState> emit,
  ) async {
    await _repository.incrementMissionsDone();
    emit(StatsState(model: _repository.buildModel()));
  }

  Future<void> _onMemberSinceSet(
    StatsMemberSinceSet event,
    Emitter<StatsState> emit,
  ) async {
    await _repository.setMemberSince(event.date);
    emit(StatsState(model: _repository.buildModel()));
  }
}
