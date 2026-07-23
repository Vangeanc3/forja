import 'package:forja/domain/entities/monk_mode_entity.dart';

class MonkModeModel extends MonkModeEntity {
  const MonkModeModel({required super.active, required super.restrictions});

  factory MonkModeModel.fromMap(Map<dynamic, dynamic> map) => MonkModeModel(
    active: map['active'] as bool? ?? false,
    restrictions: List<String>.from(
      map['restrictions'] as List? ?? const <String>[],
    ),
  );

  Map<String, dynamic> toMap() => {
    'active': active,
    'restrictions': restrictions,
  };
}
