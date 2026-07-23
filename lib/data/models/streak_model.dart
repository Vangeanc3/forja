import 'package:forja/domain/entities/streak_entity.dart';

class StreakModel extends StreakEntity {
  const StreakModel({required super.currentDays, super.startedAt});

  factory StreakModel.fromMap(Map<dynamic, dynamic> map) {
    final startedAt = _dateFrom(map['startedAt']);
    return StreakModel(
      currentDays: startedAt != null
          ? DateTime.now().difference(startedAt).inDays
          : _intFrom(map['currentDays']),
      startedAt: startedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'currentDays': currentDays,
    'startedAt': startedAt?.toIso8601String(),
  };
}

int _intFrom(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _dateFrom(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
