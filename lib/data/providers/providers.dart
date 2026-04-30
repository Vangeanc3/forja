import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mission.dart';
import '../repositories/missions_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/streak_repository.dart';
import '../../features/journal/journal_entry.dart';
import '../../features/journal/journal_repository.dart';
import '../../features/achievements/achievement_model.dart';
import '../../features/achievements/achievements_repository.dart';
import '../../features/stats/stats_repository.dart';
import '../../features/stats/weekly_report_repository.dart';
import '../../features/stats/weekly_report_model.dart';
import '../../features/weekly_challenge/weekly_challenge_repository.dart';
import '../../features/monk_mode/monk_mode_repository.dart';

// Repositories
final streakRepositoryProvider = Provider((_) => StreakRepository());
final missionsRepositoryProvider = Provider((_) => MissionsRepository());

class SettingsNotifier extends StateNotifier<SettingsRepository> {
  SettingsNotifier(this._repo) : super(_repo);
  final SettingsRepository _repo;

  Future<void> updateName(String name) async {
    await _repo.updateName(name);
    state = _repo;
  }

  Future<void> updateMode(String mode) async {
    await _repo.updateMode(mode);
    state = _repo;
  }

  Future<void> updateReason(String reason) async {
    await _repo.updateReason(reason);
    state = _repo;
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    await _repo.updateNotificationsEnabled(enabled);
    state = _repo;
  }

  Future<void> updateNotificationHour(int hour) async {
    await _repo.updateNotificationHour(hour);
    state = _repo;
  }

  Future<void> updateSupportContact(String name, String phone) async {
    await _repo.updateSupportContact(name, phone);
    state = _repo;
  }

  Future<void> updateRiskHours(List<String> hours) async {
    await _repo.updateRiskHours(hours);
    state = _repo;
  }
}

final settingsRepositoryProvider =
    StateNotifierProvider<SettingsNotifier, SettingsRepository>(
  (_) => SettingsNotifier(SettingsRepository()),
);

// Journal
final journalRepositoryProvider = Provider((_) => JournalRepository());

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  JournalNotifier(this._repo) : super(_repo.getAll());
  final JournalRepository _repo;

  Future<void> addEntry(String content) async {
    await _repo.addEntry(content);
    state = _repo.getAll();
  }
}

final journalProvider =
    StateNotifierProvider<JournalNotifier, List<JournalEntry>>(
  (ref) => JournalNotifier(ref.read(journalRepositoryProvider)),
);

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

// Weekly Report
final weeklyReportRepositoryProvider = Provider((_) => WeeklyReportRepository());

class WeeklyReportNotifier extends StateNotifier<List<WeeklyReport>> {
  WeeklyReportNotifier(this._repo) : super(_repo.getAllReports());
  final WeeklyReportRepository _repo;

  Future<void> saveReport(WeeklyReport report) async {
    await _repo.saveReport(report);
    state = _repo.getAllReports();
  }
}

final weeklyReportProvider = StateNotifierProvider<WeeklyReportNotifier, List<WeeklyReport>>(
  (ref) => WeeklyReportNotifier(ref.read(weeklyReportRepositoryProvider)),
);

// Weekly Challenge
final weeklyChallengeRepositoryProvider = Provider((_) => WeeklyChallengeRepository());

class WeeklyChallengeNotifier extends StateNotifier<bool> {
  WeeklyChallengeNotifier(this._repo) : super(_repo.isChallengeAccepted());
  final WeeklyChallengeRepository _repo;

  Future<void> accept(bool accepted) async {
    await _repo.acceptChallenge(accepted);
    state = accepted;
  }
}

final weeklyChallengeProvider = StateNotifierProvider<WeeklyChallengeNotifier, bool>(
  (ref) => WeeklyChallengeNotifier(ref.read(weeklyChallengeRepositoryProvider)),
);

// Monk Mode
final monkModeRepositoryProvider = Provider((_) => MonkModeRepository());

class MonkModeNotifier extends StateNotifier<bool> {
  MonkModeNotifier(this._repo) : super(_repo.isActive);
  final MonkModeRepository _repo;

  Future<void> toggle(bool active, List<String> restrictions) async {
    await _repo.setMonkMode(active, restrictions);
    state = active;
  }
}

final monkModeProvider = StateNotifierProvider<MonkModeNotifier, bool>(
  (ref) => MonkModeNotifier(ref.read(monkModeRepositoryProvider)),
);

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
