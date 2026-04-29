import 'dart:math' as math;

import 'package:hive/hive.dart';

import '../../core/constants.dart';

class StatsModel {
  const StatsModel({
    required this.bestStreak,
    required this.totalCleanDays,
    required this.totalRelapses,
    required this.totalMissionsDone,
    this.memberSince,
  });

  final int bestStreak;
  final int totalCleanDays;
  final int totalRelapses;
  final int totalMissionsDone;
  final DateTime? memberSince;
}

class StatsRepository {
  Box get _box => Hive.box(ForjaBoxes.stats);

  int get bestStreak =>
      _box.get('best_streak', defaultValue: 0) as int;

  int get totalCleanDays =>
      _box.get('total_clean_days', defaultValue: 0) as int;

  int get totalRelapses =>
      _box.get('total_relapses', defaultValue: 0) as int;

  int get totalMissionsDone =>
      _box.get('total_missions_done', defaultValue: 0) as int;

  DateTime? get memberSince {
    final raw = _box.get('member_since') as String?;
    return raw != null ? DateTime.parse(raw) : null;
  }

  StatsModel buildModel() => StatsModel(
        bestStreak: bestStreak,
        totalCleanDays: totalCleanDays,
        totalRelapses: totalRelapses,
        totalMissionsDone: totalMissionsDone,
        memberSince: memberSince,
      );

  // Chamado antes de resetar streak — persiste o streak atual no histórico
  Future<void> recordRelapse(int currentStreak) async {
    await _box.put('best_streak', math.max(bestStreak, currentStreak));
    await _box.put('total_clean_days', totalCleanDays + currentStreak);
    await _box.put('total_relapses', totalRelapses + 1);
  }

  Future<void> incrementMissionsDone() async {
    await _box.put('total_missions_done', totalMissionsDone + 1);
  }

  // Salva apenas na primeira chamada (membro desde o primeiro uso)
  Future<void> setMemberSince(DateTime date) async {
    if (_box.get('member_since') == null) {
      await _box.put('member_since', date.toIso8601String());
    }
  }
}
