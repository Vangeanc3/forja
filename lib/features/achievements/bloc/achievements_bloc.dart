import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/achievements_repository.dart';
import 'achievements_event.dart';
import 'achievements_state.dart';

class AchievementsBloc extends Bloc<AchievementsEvent, AchievementsState> {
  AchievementsBloc(this._repository)
    : super(AchievementsState(achievements: _repository.getAll())) {
    on<AchievementsRefreshed>(_onRefreshed);
    on<AchievementsChecked>(_onChecked);
  }

  final AchievementsRepository _repository;

  void _onRefreshed(
    AchievementsRefreshed event,
    Emitter<AchievementsState> emit,
  ) {
    emit(AchievementsState(achievements: _repository.getAll()));
  }

  Future<void> _onChecked(
    AchievementsChecked event,
    Emitter<AchievementsState> emit,
  ) async {
    final newlyUnlocked = _repository.checkNewUnlocks(event.currentDays);
    for (final achievement in newlyUnlocked) {
      await _repository.unlock(achievement.id);
    }

    emit(
      AchievementsState(
        achievements: _repository.getAll(),
        newlyUnlocked: newlyUnlocked
            .map((achievement) => achievement.copyWith(unlocked: true))
            .toList(),
      ),
    );
  }
}
