import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/monk_mode_repository.dart';
import 'monk_mode_event.dart';
import 'monk_mode_state.dart';

class MonkModeBloc extends Bloc<MonkModeEvent, MonkModeState> {
  MonkModeBloc(this._repository) : super(_snapshotFrom(_repository)) {
    on<MonkModeRefreshed>(_onRefreshed);
    on<MonkModeSaved>(_onSaved);
  }

  final MonkModeRepository _repository;

  static MonkModeState _snapshotFrom(MonkModeRepository repository) =>
      MonkModeState.fromEntity(repository.snapshot());

  void _onRefreshed(MonkModeRefreshed event, Emitter<MonkModeState> emit) {
    emit(_snapshotFrom(_repository));
  }

  Future<void> _onSaved(
    MonkModeSaved event,
    Emitter<MonkModeState> emit,
  ) async {
    await _repository.setMonkMode(event.active, event.restrictions);
    emit(_snapshotFrom(_repository));
  }
}
