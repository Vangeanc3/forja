import '../repositories/achievements_repository.dart';
import '../repositories/journal_repository.dart';
import '../repositories/missions_repository.dart';
import '../repositories/monk_mode_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/streak_repository.dart';
import '../repositories/weekly_challenge_repository.dart';
import '../repositories/weekly_report_repository.dart';
import 'firebase_sync_service.dart';

class LocalRemoteSyncService {
  const LocalRemoteSyncService({
    required FirebaseSyncService firebaseSync,
    required AchievementsRepository achievements,
    required JournalRepository journal,
    required MissionsRepository missions,
    required MonkModeRepository monkMode,
    required ProgressRepository progress,
    required SettingsRepository settings,
    required StatsRepository stats,
    required StreakRepository streak,
    required WeeklyChallengeRepository weeklyChallenge,
    required WeeklyReportRepository weeklyReport,
  }) : _firebaseSync = firebaseSync,
       _achievements = achievements,
       _journal = journal,
       _missions = missions,
       _monkMode = monkMode,
       _progress = progress,
       _settings = settings,
       _stats = stats,
       _streak = streak,
       _weeklyChallenge = weeklyChallenge,
       _weeklyReport = weeklyReport;

  final FirebaseSyncService _firebaseSync;
  final AchievementsRepository _achievements;
  final JournalRepository _journal;
  final MissionsRepository _missions;
  final MonkModeRepository _monkMode;
  final ProgressRepository _progress;
  final SettingsRepository _settings;
  final StatsRepository _stats;
  final StreakRepository _streak;
  final WeeklyChallengeRepository _weeklyChallenge;
  final WeeklyReportRepository _weeklyReport;

  Future<void> syncAll() async {
    if (!await _firebaseSync.isReady) return;

    await _settings.mergeRemote(
      await _firebaseSync.getDocument('settings', 'current'),
    );
    await _streak.mergeRemote(
      await _firebaseSync.getDocument('streak', 'current'),
    );
    await _stats.mergeRemote(
      await _firebaseSync.getDocument('stats', 'current'),
    );
    await _achievements.mergeRemote(
      await _firebaseSync.getDocument('achievements', 'current'),
    );
    await _missions.mergeRemote(
      await _firebaseSync.getDocument('missions', _today),
    );
    await _monkMode.mergeRemote(
      await _firebaseSync.getDocument('monkMode', 'current'),
    );
    await _weeklyChallenge.mergeRemote(
      await _firebaseSync.getDocument('weeklyChallenge', 'current'),
    );

    await _journal.mergeRemote(
      await _firebaseSync.getCollection('journalEntries'),
    );
    await _progress.mergeRemote(
      await _firebaseSync.getCollection('progressAreas'),
    );
    await _weeklyReport.mergeRemote(
      await _firebaseSync.getCollection('weeklyReports'),
    );
  }

  String get _today => DateTime.now().toIso8601String().substring(0, 10);
}
