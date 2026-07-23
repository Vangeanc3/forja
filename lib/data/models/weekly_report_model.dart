import 'package:forja/domain/entities/weekly_report_entity.dart';

class WeeklyReportModel extends WeeklyReportEntity {
  const WeeklyReportModel({
    required super.date,
    required super.cleanDaysCount,
    required super.totalMissionsCompleted,
    required super.challengeCompleted,
    required super.monkModeActive,
    required super.journalEntries,
    required super.closingMessage,
  });

  factory WeeklyReportModel.fromEntity(WeeklyReportEntity entity) =>
      WeeklyReportModel(
        date: entity.date,
        cleanDaysCount: entity.cleanDaysCount,
        totalMissionsCompleted: entity.totalMissionsCompleted,
        challengeCompleted: entity.challengeCompleted,
        monkModeActive: entity.monkModeActive,
        journalEntries: entity.journalEntries,
        closingMessage: entity.closingMessage,
      );

  factory WeeklyReportModel.fromMap(Map<dynamic, dynamic> map) =>
      WeeklyReportModel(
        date: DateTime.parse(map['date'] as String),
        cleanDaysCount: _intFrom(map['cleanDaysCount']),
        totalMissionsCompleted: _intFrom(map['totalMissionsCompleted']),
        challengeCompleted: map['challengeCompleted'] as bool,
        monkModeActive: map['monkModeActive'] as bool,
        journalEntries: List<String>.from(map['journalEntries'] as List),
        closingMessage: map['closingMessage'] as String,
      );

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'cleanDaysCount': cleanDaysCount,
    'totalMissionsCompleted': totalMissionsCompleted,
    'challengeCompleted': challengeCompleted,
    'monkModeActive': monkModeActive,
    'journalEntries': journalEntries,
    'closingMessage': closingMessage,
  };
}

int _intFrom(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
