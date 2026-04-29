import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mission.dart';
import '../repositories/missions_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/streak_repository.dart';
import '../../features/achievements/achievement_model.dart';
import '../../features/achievements/achievements_repository.dart';
import '../../features/stats/stats_repository.dart';

// Repositories
final streakRepositoryProvider = Provider((_) => StreakRepository());
final missionsRepositoryProvider = Provider((_) => MissionsRepository());
final settingsRepositoryProvider = Provider((_) => SettingsRepository());

// Streak
class StreakNotifier extends StateNotifier<int> {
  StreakNotifier(this._repo) : super(_repo.currentDays);

  final StreakRepository _repo;

  Future<void> start() async {
    await _repo.startStreak();
    state = 0;
  }

  Future<void> relapse() async {
    await _repo.resetStreak();
    await _repo.startStreak();
    state = 0;
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, int>(
  (ref) => StreakNotifier(ref.read(streakRepositoryProvider)),
);

// Missions
class MissionsNotifier extends StateNotifier<List<Mission>> {
  MissionsNotifier(this._repo) : super(_repo.getTodayMissions());

  final MissionsRepository _repo;

  void toggle(String id) {
    _repo.toggleMission(id);
    state = _repo.getTodayMissions();
  }
}

final missionsProvider = StateNotifierProvider<MissionsNotifier, List<Mission>>(
  (ref) => MissionsNotifier(ref.read(missionsRepositoryProvider)),
);

// Achievements
final achievementsRepositoryProvider = Provider((_) => AchievementsRepository());

class AchievementsNotifier extends StateNotifier<List<Achievement>> {
  AchievementsNotifier(this._repo) : super(_repo.getAll());

  final AchievementsRepository _repo;

  // Persiste novos desbloqueios e retorna os recém-conquistados
  Future<List<Achievement>> checkAndUnlock(int currentDays) async {
    final newlyUnlocked = _repo.checkNewUnlocks(currentDays);
    for (final a in newlyUnlocked) {
      await _repo.unlock(a.id);
    }
    if (newlyUnlocked.isNotEmpty) {
      state = _repo.getAll();
    }
    return newlyUnlocked.map((a) => a.copyWith(unlocked: true)).toList();
  }
}

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, List<Achievement>>(
  (ref) => AchievementsNotifier(ref.read(achievementsRepositoryProvider)),
);

// Stats
final statsRepositoryProvider = Provider((_) => StatsRepository());

class StatsNotifier extends StateNotifier<StatsModel> {
  StatsNotifier(this._repo) : super(_repo.buildModel());

  final StatsRepository _repo;

  Future<void> recordRelapse(int currentStreak) async {
    await _repo.recordRelapse(currentStreak);
    state = _repo.buildModel();
  }

  Future<void> incrementMissions() async {
    await _repo.incrementMissionsDone();
    state = _repo.buildModel();
  }

  Future<void> setMemberSince(DateTime date) async {
    await _repo.setMemberSince(date);
    state = _repo.buildModel();
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsModel>(
  (ref) => StatsNotifier(ref.read(statsRepositoryProvider)),
);
