import 'package:equatable/equatable.dart';

import 'package:forja/domain/entities/weekly_report_entity.dart';

class WeeklyReportState extends Equatable {
  const WeeklyReportState({required this.reports});

  final List<WeeklyReportEntity> reports;

  @override
  List<Object?> get props => [reports];
}
