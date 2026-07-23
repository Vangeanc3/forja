import 'package:equatable/equatable.dart';

import 'package:forja/domain/entities/weekly_report_entity.dart';

abstract class WeeklyReportEvent extends Equatable {
  const WeeklyReportEvent();

  @override
  List<Object?> get props => [];
}

class WeeklyReportsRefreshed extends WeeklyReportEvent {
  const WeeklyReportsRefreshed();
}

class WeeklyReportSaved extends WeeklyReportEvent {
  const WeeklyReportSaved(this.report);

  final WeeklyReportEntity report;

  @override
  List<Object?> get props => [report];
}

class WeeklyCurrentReportGenerated extends WeeklyReportEvent {
  const WeeklyCurrentReportGenerated({
    required this.cleanDaysThisWeek,
    required this.missionsDoneThisWeek,
    required this.challengeCompleted,
    required this.monkModeActive,
    required this.journalEntries,
  });

  final int cleanDaysThisWeek;
  final int missionsDoneThisWeek;
  final bool challengeCompleted;
  final bool monkModeActive;
  final List<String> journalEntries;

  @override
  List<Object?> get props => [
    cleanDaysThisWeek,
    missionsDoneThisWeek,
    challengeCompleted,
    monkModeActive,
    journalEntries,
  ];
}
