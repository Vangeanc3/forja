import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/missions_repository.dart';
import 'missions_event.dart';
import 'missions_state.dart';

class MissionsBloc extends Bloc<MissionsEvent, MissionsState> {
  MissionsBloc(this._repository)
    : super(MissionsState(missions: _repository.getTodayMissions())) {
    on<MissionsRefreshed>(_onRefreshed);
    on<MissionToggled>(_onToggled);
  }

  final MissionsRepository _repository;

  void _onRefreshed(MissionsRefreshed event, Emitter<MissionsState> emit) {
    emit(MissionsState(missions: _repository.getTodayMissions()));
  }

  void _onToggled(MissionToggled event, Emitter<MissionsState> emit) {
    _repository.toggleMission(event.id);
    emit(MissionsState(missions: _repository.getTodayMissions()));
  }
}
