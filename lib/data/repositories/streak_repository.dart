import 'package:hive/hive.dart';
import 'package:forja/data/models/streak_model.dart';

import '../../core/constants.dart';
import '../services/firebase_sync_service.dart';

class StreakRepository {
  StreakRepository({FirebaseSyncService? firebaseSync})
    : _firebaseSync = firebaseSync;

  final FirebaseSyncService? _firebaseSync;

  Box get _box => Hive.box(ForjaBoxes.streak);

  DateTime? get streakStart {
    final raw = _box.get(ForjaStorage.streakStartKey) as String?;
    return raw != null ? DateTime.parse(raw) : null;
  }

  Future<void> startStreak() async {
    await _box.put(
      ForjaStorage.streakStartKey,
      DateTime.now().toIso8601String(),
    );
    await _sync();
  }

  Future<void> resetStreak() async {
    await _box.delete(ForjaStorage.streakStartKey);
    await _sync();
  }

  int get currentDays {
    final start = streakStart;
    if (start == null) return 0;
    return DateTime.now().difference(start).inDays;
  }

  StreakModel snapshot() =>
      StreakModel(currentDays: currentDays, startedAt: streakStart);

  Future<void> _sync() =>
      _firebaseSync?.setDocument('streak', 'current', snapshot().toMap()) ??
      Future.value();

  Future<void> syncCurrent() => _sync();

  Future<void> mergeRemote(FirebaseSyncDocument? document) async {
    if (document == null) {
      await syncCurrent();
      return;
    }

    final localStartedAt = streakStart;
    final remoteStartedAt = StreakModel.fromMap(document.data).startedAt;
    final mergedStartedAt = _earliest(localStartedAt, remoteStartedAt);

    if (mergedStartedAt == null) {
      await _box.delete(ForjaStorage.streakStartKey);
    } else {
      await _box.put(
        ForjaStorage.streakStartKey,
        mergedStartedAt.toIso8601String(),
      );
    }

    await syncCurrent();
  }

  DateTime? _earliest(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isBefore(second) ? first : second;
  }
}
