class WeeklyReportEntity {
  const WeeklyReportEntity({
    required this.date,
    required this.cleanDaysCount,
    required this.totalMissionsCompleted,
    required this.challengeCompleted,
    required this.monkModeActive,
    required this.journalEntries,
    required this.closingMessage,
  });

  final DateTime date;
  final int cleanDaysCount;
  final int totalMissionsCompleted;
  final bool challengeCompleted;
  final bool monkModeActive;
  final List<String> journalEntries;
  final String closingMessage;
}
