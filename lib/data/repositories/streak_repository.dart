import 'package:hive/hive.dart';

import '../../core/constants.dart';

class StreakRepository {
  Box get _box => Hive.box(ForjaBoxes.streak);

  DateTime? get streakStart {
    final raw = _box.get(ForjaStorage.streakStartKey) as String?;
    return raw != null ? DateTime.parse(raw) : null;
  }

  Future<void> startStreak() =>
      _box.put(ForjaStorage.streakStartKey, DateTime.now().toIso8601String());

  Future<void> resetStreak() => _box.delete(ForjaStorage.streakStartKey);

  int get currentDays {
    final start = streakStart;
    if (start == null) return 0;
    return DateTime.now().difference(start).inDays;
  }
}
