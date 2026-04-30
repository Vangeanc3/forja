class WeeklyReport {
  final DateTime date;
  final int cleanDaysCount;
  final int totalMissionsCompleted;
  final bool challengeCompleted;
  final bool monkModeActive;
  final List<String> journalEntries;
  final String closingMessage;

  WeeklyReport({
    required this.date,
    required this.cleanDaysCount,
    required this.totalMissionsCompleted,
    required this.challengeCompleted,
    required this.monkModeActive,
    required this.journalEntries,
    required this.closingMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'cleanDaysCount': cleanDaysCount,
      'totalMissionsCompleted': totalMissionsCompleted,
      'challengeCompleted': challengeCompleted,
      'monkModeActive': monkModeActive,
      'journalEntries': journalEntries,
      'closingMessage': closingMessage,
    };
  }

  factory WeeklyReport.fromMap(Map<dynamic, dynamic> map) {
    return WeeklyReport(
      date: DateTime.parse(map['date'] as String),
      cleanDaysCount: map['cleanDaysCount'] as int,
      totalMissionsCompleted: map['totalMissionsCompleted'] as int,
      challengeCompleted: map['challengeCompleted'] as bool,
      monkModeActive: map['monkModeActive'] as bool,
      journalEntries: List<String>.from(map['journalEntries'] as List),
      closingMessage: map['closingMessage'] as String,
    );
  }
}
