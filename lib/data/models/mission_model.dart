import 'package:forja/domain/entities/mission_entity.dart';

class MissionModel extends MissionEntity {
  const MissionModel({
    required super.id,
    required super.title,
    super.completed = false,
  });

  factory MissionModel.fromEntity(MissionEntity entity) => MissionModel(
    id: entity.id,
    title: entity.title,
    completed: entity.completed,
  );

  factory MissionModel.fromMap(Map<dynamic, dynamic> map) => MissionModel(
    id: map['id'] as String,
    title: map['title'] as String,
    completed: map['completed'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'completed': completed,
  };

  @override
  MissionModel copyWith({bool? completed}) => MissionModel(
    id: id,
    title: title,
    completed: completed ?? this.completed,
  );
}
