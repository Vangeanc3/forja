import 'package:hive/hive.dart';

import '../../core/constants.dart';
import '../models/mission.dart';

const _defaults = [
  ('exercicio', 'Exercício físico (30 min)'),
  ('leitura', 'Leitura (20 min)'),
  ('meditacao', 'Meditação (10 min)'),
  ('banho_frio', 'Banho frio'),
  ('sem_telas', 'Sem telas antes de dormir'),
];

class MissionsRepository {
  Box get _box => Hive.box(ForjaBoxes.missions);

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  List<Mission> getTodayMissions() {
    final today = _today;
    final storedDate = _box.get('date') as String?;

    if (storedDate != today) {
      final missions = _defaults.map((t) => Mission(id: t.$1, title: t.$2)).toList();
      _persist(missions, today);
      return missions;
    }

    final raw = _box.get('list') as List?;
    if (raw == null) {
      final missions = _defaults.map((t) => Mission(id: t.$1, title: t.$2)).toList();
      _persist(missions, today);
      return missions;
    }

    return raw.map((m) => Mission.fromMap(m as Map)).toList();
  }

  void toggleMission(String id) {
    final missions = getTodayMissions();
    final idx = missions.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    final updated = missions..[idx] = missions[idx].copyWith(
          completed: !missions[idx].completed,
        );
    _persist(updated, _today);
  }

  void _persist(List<Mission> missions, String date) {
    _box.put('list', missions.map((m) => m.toMap()).toList());
    _box.put('date', date);
  }
}
