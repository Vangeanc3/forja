import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/weekly_report_repository.dart';
import 'weekly_report_event.dart';
import 'weekly_report_state.dart';

class WeeklyReportBloc extends Bloc<WeeklyReportEvent, WeeklyReportState> {
  WeeklyReportBloc(this._repository)
    : super(WeeklyReportState(reports: _repository.getAllReports())) {
    on<WeeklyReportsRefreshed>(_onRefreshed);
    on<WeeklyReportSaved>(_onSaved);
    on<WeeklyCurrentReportGenerated>(_onCurrentReportGenerated);
  }

  final WeeklyReportRepository _repository;

  void _onRefreshed(
    WeeklyReportsRefreshed event,
    Emitter<WeeklyReportState> emit,
  ) {
    emit(WeeklyReportState(reports: _repository.getAllReports()));
  }

  Future<void> _onSaved(
    WeeklyReportSaved event,
    Emitter<WeeklyReportState> emit,
  ) async {
    await _repository.saveReport(event.report);
    emit(WeeklyReportState(reports: _repository.getAllReports()));
  }

  Future<void> _onCurrentReportGenerated(
    WeeklyCurrentReportGenerated event,
    Emitter<WeeklyReportState> emit,
  ) async {
    if (_repository.hasReportForThisWeek()) return;

    final report = _repository.generateCurrentReport(
      cleanDaysThisWeek: event.cleanDaysThisWeek,
      missionsDoneThisWeek: event.missionsDoneThisWeek,
      challengeCompleted: event.challengeCompleted,
      monkModeActive: event.monkModeActive,
      journalEntries: event.journalEntries,
    );

    await _repository.saveReport(report);
    emit(WeeklyReportState(reports: _repository.getAllReports()));
  }
}
