import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/weekly_challenge_repository.dart';
import 'weekly_challenge_event.dart';
import 'weekly_challenge_state.dart';

class WeeklyChallengeBloc
    extends Bloc<WeeklyChallengeEvent, WeeklyChallengeState> {
  WeeklyChallengeBloc(this._repository) : super(_snapshotFrom(_repository)) {
    on<WeeklyChallengeRefreshed>(_onRefreshed);
    on<WeeklyChallengeAcceptanceChanged>(_onAcceptanceChanged);
  }

  final WeeklyChallengeRepository _repository;

  static WeeklyChallengeState _snapshotFrom(
    WeeklyChallengeRepository repository,
  ) {
    repository.checkAndResetIfNeeded();
    return WeeklyChallengeState(
      challenge: repository.getCurrentChallenge(),
      accepted: repository.isChallengeAccepted(),
    );
  }

  void _onRefreshed(
    WeeklyChallengeRefreshed event,
    Emitter<WeeklyChallengeState> emit,
  ) {
    emit(_snapshotFrom(_repository));
  }

  Future<void> _onAcceptanceChanged(
    WeeklyChallengeAcceptanceChanged event,
    Emitter<WeeklyChallengeState> emit,
  ) async {
    await _repository.acceptChallenge(event.accepted);
    emit(_snapshotFrom(_repository));
  }
}
