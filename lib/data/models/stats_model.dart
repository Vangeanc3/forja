import 'package:forja/domain/entities/stats_entity.dart';

class StatsModel extends StatsEntity {
  const StatsModel({
    required super.bestStreak,
    required super.totalCleanDays,
    required super.totalRelapses,
    required super.totalMissionsDone,
    super.memberSince,
    super.relapses = const [],
  });

  factory StatsModel.fromMap(Map<dynamic, dynamic> map) => StatsModel(
    bestStreak: _intFrom(map['bestStreak']),
    totalCleanDays: _intFrom(map['totalCleanDays']),
    totalRelapses: _intFrom(map['totalRelapses']),
    totalMissionsDone: _intFrom(map['totalMissionsDone']),
    memberSince: _dateFrom(map['memberSince']),
    relapses: (map['relapses'] as List? ?? const [])
        .whereType<Map>()
        .map(RelapseEntryModel.fromMap)
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'bestStreak': bestStreak,
    'totalCleanDays': totalCleanDays,
    'totalRelapses': totalRelapses,
    'totalMissionsDone': totalMissionsDone,
    'memberSince': memberSince?.toIso8601String(),
    'relapses': relapses
        .map((entry) => RelapseEntryModel.fromEntity(entry).toMap())
        .toList(),
  };
}

class RelapseEntryModel extends RelapseEntryEntity {
  const RelapseEntryModel({
    required super.dateTime,
    required super.streakDuration,
  });

  factory RelapseEntryModel.fromEntity(RelapseEntryEntity entity) =>
      RelapseEntryModel(
        dateTime: entity.dateTime,
        streakDuration: entity.streakDuration,
      );

  factory RelapseEntryModel.fromMap(Map<dynamic, dynamic> map) =>
      RelapseEntryModel(
        dateTime: _dateFrom(map['dateTime']) ?? DateTime.now(),
        streakDuration: _intFrom(map['streakDuration']),
      );

  Map<String, dynamic> toMap() => {
    'dateTime': dateTime.toIso8601String(),
    'streakDuration': streakDuration,
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
