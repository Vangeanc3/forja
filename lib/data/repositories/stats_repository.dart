import 'dart:math' as math;

import 'package:hive/hive.dart';
import 'package:forja/data/models/stats_model.dart';
import 'package:forja/domain/entities/stats_entity.dart';

import '../../core/constants.dart';
import '../services/firebase_sync_service.dart';

class StatsRepository {
  StatsRepository({FirebaseSyncService? firebaseSync})
    : _firebaseSync = firebaseSync;

  final FirebaseSyncService? _firebaseSync;

  Box get _box => Hive.box(ForjaBoxes.stats);

  int get bestStreak => _box.get('best_streak', defaultValue: 0) as int;

  int get totalCleanDays =>
      _box.get('total_clean_days', defaultValue: 0) as int;

  int get totalRelapses => _box.get('total_relapses', defaultValue: 0) as int;

  int get totalMissionsDone =>
      _box.get('total_missions_done', defaultValue: 0) as int;

  DateTime? get memberSince {
    final raw = _box.get('member_since') as String?;
    return raw != null ? DateTime.parse(raw) : null;
  }

  List<RelapseEntryEntity> get relapses {
    final raw = _box.get('relapses') as List?;
    if (raw == null) return [];
    return raw.map((e) => RelapseEntryModel.fromMap(e as Map)).toList();
  }

  StatsModel buildModel() => StatsModel(
    bestStreak: bestStreak,
    totalCleanDays: totalCleanDays,
    totalRelapses: totalRelapses,
    totalMissionsDone: totalMissionsDone,
    memberSince: memberSince,
    relapses: relapses,
  );

  // Chamado antes de resetar streak — persiste o streak atual no histórico
  Future<void> recordRelapse(int currentStreak) async {
    await _box.put('best_streak', math.max(bestStreak, currentStreak));
    await _box.put('total_clean_days', totalCleanDays + currentStreak);
    await _box.put('total_relapses', totalRelapses + 1);

    final currentRelapses = relapses;
    currentRelapses.add(
      RelapseEntryModel(
        dateTime: DateTime.now(),
        streakDuration: currentStreak,
      ),
    );
    await _box.put(
      'relapses',
      currentRelapses
          .map((e) => RelapseEntryModel.fromEntity(e).toMap())
          .toList(),
    );
    await _sync();
  }

  Future<void> incrementMissionsDone() async {
    await _box.put('total_missions_done', totalMissionsDone + 1);
    await _sync();
  }

  // Salva apenas na primeira chamada (membro desde o primeiro uso)
  Future<void> setMemberSince(DateTime date) async {
    if (_box.get('member_since') == null) {
      await _box.put('member_since', date.toIso8601String());
      await _sync();
    }
  }

  Future<void> _sync() =>
      _firebaseSync?.setDocument('stats', 'current', buildModel().toMap()) ??
      Future.value();

  Future<void> syncCurrent() => _sync();

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> mergeRemote(FirebaseSyncDocument? document) async {
    if (document == null) {
      await syncCurrent();
      return;
    }

    final local = buildModel();
    final remote = StatsModel.fromMap(document.data);
    final mergedRelapses = _mergeRelapses(local.relapses, remote.relapses);
    final merged = StatsModel(
      bestStreak: math.max(local.bestStreak, remote.bestStreak),
      totalCleanDays: math.max(local.totalCleanDays, remote.totalCleanDays),
      totalRelapses: [
        local.totalRelapses,
        remote.totalRelapses,
        mergedRelapses.length,
      ].reduce(math.max),
      totalMissionsDone: math.max(
        local.totalMissionsDone,
        remote.totalMissionsDone,
      ),
      memberSince: _earliest(local.memberSince, remote.memberSince),
      relapses: mergedRelapses,
    );

    await _writeModel(merged);
    await syncCurrent();
  }

  Future<void> _writeModel(StatsModel model) async {
    await _box.put('best_streak', model.bestStreak);
    await _box.put('total_clean_days', model.totalCleanDays);
    await _box.put('total_relapses', model.totalRelapses);
    await _box.put('total_missions_done', model.totalMissionsDone);
    if (model.memberSince == null) {
      await _box.delete('member_since');
    } else {
      await _box.put('member_since', model.memberSince!.toIso8601String());
    }
    await _box.put(
      'relapses',
      model.relapses
          .map((entry) => RelapseEntryModel.fromEntity(entry).toMap())
          .toList(),
    );
  }

  List<RelapseEntryEntity> _mergeRelapses(
    List<RelapseEntryEntity> local,
    List<RelapseEntryEntity> remote,
  ) {
    final byKey = <String, RelapseEntryEntity>{};
    for (final entry in [...local, ...remote]) {
      byKey[_relapseKey(entry)] = entry;
    }

    final merged = byKey.values.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return merged;
  }

  String _relapseKey(RelapseEntryEntity entry) =>
      '${entry.dateTime.microsecondsSinceEpoch}:${entry.streakDuration}';

  DateTime? _earliest(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isBefore(second) ? first : second;
  }
}
