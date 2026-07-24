import 'package:hive/hive.dart';
import 'package:forja/domain/entities/achievement_entity.dart';

import '../../core/constants.dart';
import '../services/firebase_sync_service.dart';

class AchievementsRepository {
  AchievementsRepository({FirebaseSyncService? firebaseSync})
    : _firebaseSync = firebaseSync;

  final FirebaseSyncService? _firebaseSync;

  Box get _box => Hive.box(ForjaBoxes.achievements);

  Set<String> get _unlockedIds {
    final raw = _box.get('unlocked') as List?;
    return raw?.cast<String>().toSet() ?? {};
  }

  List<AchievementEntity> getAll() {
    final unlocked = _unlockedIds;
    return kAchievements
        .map((a) => a.copyWith(unlocked: unlocked.contains(a.id)))
        .toList();
  }

  // Retorna conquistas que o streak já merece mas ainda não foram persistidas
  List<AchievementEntity> checkNewUnlocks(int currentDays) {
    final already = _unlockedIds;
    return kAchievements
        .where((a) => currentDays >= a.daysRequired && !already.contains(a.id))
        .toList();
  }

  Future<void> unlock(String id) async {
    final ids = _unlockedIds..add(id);
    await _box.put('unlocked', ids.toList());
    await syncCurrent();
  }

  Future<void> syncCurrent() =>
      _firebaseSync?.setDocument('achievements', 'current', {
        'unlockedIds': _unlockedIds.toList(),
      }) ??
      Future.value();

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> mergeRemote(FirebaseSyncDocument? document) async {
    if (document == null) {
      await syncCurrent();
      return;
    }

    final remoteIds =
        (document.data['unlockedIds'] as List?)?.cast<String>().toSet() ??
        <String>{};
    final mergedIds = {..._unlockedIds, ...remoteIds};

    await _box.put('unlocked', mergedIds.toList());
    await syncCurrent();
  }
}
