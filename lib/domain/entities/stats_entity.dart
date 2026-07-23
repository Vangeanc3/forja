class StatsEntity {
  const StatsEntity({
    required this.bestStreak,
    required this.totalCleanDays,
    required this.totalRelapses,
    required this.totalMissionsDone,
    this.memberSince,
    this.relapses = const [],
  });

  final int bestStreak;
  final int totalCleanDays;
  final int totalRelapses;
  final int totalMissionsDone;
  final DateTime? memberSince;
  final List<RelapseEntryEntity> relapses;
}

class RelapseEntryEntity {
  const RelapseEntryEntity({
    required this.dateTime,
    required this.streakDuration,
  });

  final DateTime dateTime;
  final int streakDuration;
}
