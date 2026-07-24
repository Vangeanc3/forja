import 'dart:async';

import 'package:hive/hive.dart';
import 'package:forja/data/models/weekly_challenge_model.dart';
import 'package:forja/domain/entities/weekly_challenge_entity.dart';
import '../../core/constants.dart';
import '../services/firebase_sync_service.dart';

class WeeklyChallengeRepository {
  WeeklyChallengeRepository({FirebaseSyncService? firebaseSync})
    : _firebaseSync = firebaseSync;

  final FirebaseSyncService? _firebaseSync;

  Box get _box => Hive.box(ForjaBoxes.weeklyChallenge);

  WeeklyChallengeEntity getCurrentChallenge() {
    final now = DateTime.now();
    // Muda o desafio baseado na semana do ano (aproximado)
    final weekIndex = (now.millisecondsSinceEpoch / (1000 * 60 * 60 * 24 * 7))
        .floor();
    return kWeeklyChallenges[weekIndex % kWeeklyChallenges.length];
  }

  bool isChallengeAccepted() {
    final lastDateRaw = _box.get(ForjaStorage.lastChallengeDateKey) as String?;
    if (lastDateRaw == null) return false;

    return _box.get(ForjaStorage.acceptedChallengeKey, defaultValue: false)
        as bool;
  }

  Future<void> acceptChallenge(bool accepted) async {
    final challenge = getCurrentChallenge();
    await _box.put(ForjaStorage.acceptedChallengeKey, accepted);
    await _box.put(
      ForjaStorage.lastChallengeDateKey,
      DateTime.now().toIso8601String(),
    );
    await _syncChallenge(challenge);
  }

  // Verifica se o desafio mudou para resetar o status de aceito
  void checkAndResetIfNeeded() {
    final lastDateRaw = _box.get(ForjaStorage.lastChallengeDateKey) as String?;
    if (lastDateRaw == null) return;

    final lastDate = DateTime.parse(lastDateRaw);
    final now = DateTime.now();

    // Simplificação: se mudou a semana (baseado no índice)
    final lastWeekIndex =
        (lastDate.millisecondsSinceEpoch / (1000 * 60 * 60 * 24 * 7)).floor();
    final currentWeekIndex =
        (now.millisecondsSinceEpoch / (1000 * 60 * 60 * 24 * 7)).floor();

    if (currentWeekIndex > lastWeekIndex) {
      _box.put(ForjaStorage.acceptedChallengeKey, false);
      unawaited(_syncChallenge(getCurrentChallenge(), acceptedOverride: false));
    }
  }

  Future<void> syncCurrent() => _syncChallenge(getCurrentChallenge());

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> mergeRemote(FirebaseSyncDocument? document) async {
    if (document == null) {
      await syncCurrent();
      return;
    }

    final remoteLastDate = _dateFrom(document.data['lastChallengeDate']);
    final localLastDate = _dateFrom(
      _box.get(ForjaStorage.lastChallengeDateKey),
    );
    final shouldApplyRemote =
        remoteLastDate != null &&
        (localLastDate == null || remoteLastDate.isAfter(localLastDate));

    if (shouldApplyRemote) {
      await _box.put(
        ForjaStorage.acceptedChallengeKey,
        document.data['accepted'] as bool? ?? false,
      );
      await _box.put(
        ForjaStorage.lastChallengeDateKey,
        remoteLastDate.toIso8601String(),
      );
    }

    await syncCurrent();
  }

  Future<void> _syncChallenge(
    WeeklyChallengeEntity challenge, {
    bool? acceptedOverride,
  }) {
    return _firebaseSync?.setDocument('weeklyChallenge', 'current', {
          ...WeeklyChallengeModel.fromEntity(challenge).toMap(),
          'accepted': acceptedOverride ?? isChallengeAccepted(),
          'lastChallengeDate': _box.get(ForjaStorage.lastChallengeDateKey),
        }) ??
        Future.value();
  }

  DateTime? _dateFrom(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
