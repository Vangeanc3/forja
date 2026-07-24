import 'package:hive/hive.dart';
import 'package:forja/data/models/weekly_report_model.dart';
import 'package:forja/domain/entities/weekly_report_entity.dart';
import '../../core/constants.dart';
import '../services/firebase_sync_service.dart';

class WeeklyReportRepository {
  WeeklyReportRepository({FirebaseSyncService? firebaseSync})
    : _firebaseSync = firebaseSync;

  final FirebaseSyncService? _firebaseSync;
  final Box _reportBox = Hive.box(ForjaBoxes.weeklyReports);

  List<WeeklyReportEntity> getAllReports() {
    final raw = _reportBox.get('reports', defaultValue: []) as List;
    return raw
        .map((e) => WeeklyReportModel.fromMap(e as Map))
        .toList()
        .reversed
        .toList();
  }

  Future<void> saveReport(WeeklyReportEntity report) async {
    final reports = getAllReports().reversed.toList();
    reports.add(report);
    await _writeReports(reports);
    final reportModel = WeeklyReportModel.fromEntity(report);
    await _syncReport(reportModel);
  }

  Future<void> syncAll() async {
    for (final report in getAllReports()) {
      await _syncReport(WeeklyReportModel.fromEntity(report));
    }
  }

  Future<void> clear() async {
    await _reportBox.clear();
  }

  Future<void> mergeRemote(List<FirebaseSyncDocument> documents) async {
    final byId = {
      for (final report in getAllReports()) _reportId(report): report,
    };

    for (final document in documents) {
      final report = WeeklyReportModel.fromMap(document.data);
      byId.putIfAbsent(_reportId(report), () => report);
    }

    final merged = byId.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    await _writeReports(merged);
    await syncAll();
  }

  WeeklyReportEntity generateCurrentReport({
    required int cleanDaysThisWeek,
    required int missionsDoneThisWeek,
    required bool challengeCompleted,
    required bool monkModeActive,
    required List<String> journalEntries,
  }) {
    String message;
    if (cleanDaysThisWeek >= 7) {
      message = "Semana perfeita. Você é aço.";
    } else if (cleanDaysThisWeek >= 5) {
      message = "Quase lá. Continue forjando.";
    } else if (cleanDaysThisWeek >= 3) {
      message = "Semana difícil. Mas você ainda está aqui.";
    } else {
      message = "Levanta. A forja não fecha.";
    }

    return WeeklyReportModel(
      date: DateTime.now(),
      cleanDaysCount: cleanDaysThisWeek,
      totalMissionsCompleted: missionsDoneThisWeek,
      challengeCompleted: challengeCompleted,
      monkModeActive: monkModeActive,
      journalEntries: journalEntries,
      closingMessage: message,
    );
  }

  // Verifica se já existe um relatório para a semana atual (domingo atual)
  bool hasReportForThisWeek() {
    final reports = getAllReports();
    if (reports.isEmpty) return false;

    final lastReport =
        reports.first; // Já está revertido, então first é o mais recente
    final now = DateTime.now();

    // Considera a mesma semana se a diferença for menor que 7 dias e o dia do último relatório for domingo
    return now.difference(lastReport.date).inDays < 7 &&
        lastReport.date.weekday == DateTime.sunday;
  }

  Future<void> _syncReport(WeeklyReportModel report) {
    return _firebaseSync?.setDocument(
          'weeklyReports',
          report.date.microsecondsSinceEpoch.toString(),
          report.toMap(),
        ) ??
        Future.value();
  }

  Future<void> _writeReports(List<WeeklyReportEntity> reports) {
    return _reportBox.put(
      'reports',
      reports.map((e) => WeeklyReportModel.fromEntity(e).toMap()).toList(),
    );
  }

  String _reportId(WeeklyReportEntity report) =>
      report.date.microsecondsSinceEpoch.toString();
}
