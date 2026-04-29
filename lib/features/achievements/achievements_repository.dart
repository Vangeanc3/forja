import 'package:hive/hive.dart';

import '../../core/constants.dart';
import 'achievement_model.dart';

class AchievementsRepository {
  Box get _box => Hive.box(ForjaBoxes.achievements);

  Set<String> get _unlockedIds {
    final raw = _box.get('unlocked') as List?;
    return raw?.cast<String>().toSet() ?? {};
  }

  List<Achievement> getAll() {
    final unlocked = _unlockedIds;
    return kAchievements
        .map((a) => a.copyWith(unlocked: unlocked.contains(a.id)))
        .toList();
  }

  // Retorna conquistas que o streak já merece mas ainda não foram persistidas
  List<Achievement> checkNewUnlocks(int currentDays) {
    final already = _unlockedIds;
    return kAchievements
        .where((a) => currentDays >= a.daysRequired && !already.contains(a.id))
        .toList();
  }

  Future<void> unlock(String id) async {
    final ids = _unlockedIds..add(id);
    await _box.put('unlocked', ids.toList());
  }
}
