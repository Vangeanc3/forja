import 'package:hive/hive.dart';
import '../../core/constants.dart';
import '../journal/journal_repository.dart';
import '../monk_mode/monk_mode_repository.dart';
import '../weekly_challenge/weekly_challenge_repository.dart';
import 'weekly_report_model.dart';
import '../../data/repositories/missions_repository.dart';

class WeeklyReportRepository {
  final Box _reportBox = Hive.box(ForjaBoxes.weeklyReports);
  final Box _statsBox = Hive.box(ForjaBoxes.stats);

  List<WeeklyReport> getAllReports() {
    final raw = _reportBox.get('reports', defaultValue: []) as List;
    return raw.map((e) => WeeklyReport.fromMap(e as Map)).toList().reversed.toList();
  }

  Future<void> saveReport(WeeklyReport report) async {
    final reports = getAllReports().reversed.toList();
    reports.add(report);
    await _reportBox.put('reports', reports.map((e) => e.toMap()).toList());
  }

  WeeklyReport generateCurrentReport({
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

    return WeeklyReport(
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
    
    final lastReport = reports.first; // Já está revertido, então first é o mais recente
    final now = DateTime.now();
    
    // Considera a mesma semana se a diferença for menor que 7 dias e o dia do último relatório for domingo
    return now.difference(lastReport.date).inDays < 7 && lastReport.date.weekday == DateTime.sunday;
  }
}
