import 'dart:async';

import 'package:hive/hive.dart';
import 'package:forja/data/models/mission_model.dart';
import 'package:forja/domain/entities/mission_entity.dart';

import '../../core/constants.dart';
import '../services/firebase_sync_service.dart';

const _defaults = [
  ('exercicio', 'Exercício físico (30 min)'),
  ('leitura', 'Leitura (20 min)'),
  ('meditacao', 'Meditação (10 min)'),
  ('banho_frio', 'Banho frio'),
  ('sem_telas', 'Sem telas antes de dormir'),
];

class MissionsRepository {
  MissionsRepository({FirebaseSyncService? firebaseSync})
    : _firebaseSync = firebaseSync;

  final FirebaseSyncService? _firebaseSync;

  Box get _box => Hive.box(ForjaBoxes.missions);

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  List<MissionEntity> getTodayMissions() {
    final today = _today;
    final storedDate = _box.get('date') as String?;

    if (storedDate != today) {
      final missions = _defaults
          .map((t) => MissionModel(id: t.$1, title: t.$2))
          .toList();
      _persist(missions, today);
      return missions;
    }

    final raw = _box.get('list') as List?;
    if (raw == null) {
      final missions = _defaults
          .map((t) => MissionModel(id: t.$1, title: t.$2))
          .toList();
      _persist(missions, today);
      return missions;
    }

    return raw.map((m) => MissionModel.fromMap(m as Map)).toList();
  }

  void toggleMission(String id) {
    final missions = getTodayMissions();
    final idx = missions.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    final updated = missions
      ..[idx] = missions[idx].copyWith(completed: !missions[idx].completed);
    _persist(updated, _today);
  }

  void _persist(List<MissionEntity> missions, String date) {
    _writeLocalMissions(missions, date);
    unawaited(_syncMissions(missions, date));
  }

  void _writeLocalMissions(List<MissionEntity> missions, String date) {
    _box.put(
      'list',
      missions.map((m) => MissionModel.fromEntity(m).toMap()).toList(),
    );
    _box.put('date', date);
  }

  Future<void> syncCurrent() => _syncMissions(getTodayMissions(), _today);

  Future<void> mergeRemote(FirebaseSyncDocument? document) async {
    if (document == null) {
      await syncCurrent();
      return;
    }

    final local = getTodayMissions();
    final remoteList = document.data['list'] as List? ?? const [];
    final remote = remoteList
        .whereType<Map>()
        .map(MissionModel.fromMap)
        .toList(growable: false);
    final byId = {
      for (final mission in [...local, ...remote]) mission.id: mission,
    };

    for (final mission in local) {
      final remoteMission = _findById(remote, mission.id);
      if (remoteMission != null) {
        byId[mission.id] = MissionModel(
          id: mission.id,
          title: mission.title,
          completed: mission.completed || remoteMission.completed,
        );
      }
    }

    final merged = _defaults
        .map((defaultMission) {
          final stored = byId[defaultMission.$1];
          return MissionModel(
            id: defaultMission.$1,
            title: stored?.title ?? defaultMission.$2,
            completed: stored?.completed ?? false,
          );
        })
        .toList(growable: false);

    _writeLocalMissions(merged, _today);
    await syncCurrent();
  }

  Future<void> _syncMissions(List<MissionEntity> missions, String date) {
    return _firebaseSync?.setDocument('missions', date, {
          'date': date,
          'list': missions
              .map((mission) => MissionModel.fromEntity(mission).toMap())
              .toList(),
        }) ??
        Future.value();
  }

  MissionModel? _findById(List<MissionModel> missions, String id) {
    for (final mission in missions) {
      if (mission.id == id) return mission;
    }
    return null;
  }
}
