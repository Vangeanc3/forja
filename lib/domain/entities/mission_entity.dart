class MissionEntity {
  const MissionEntity({
    required this.id,
    required this.title,
    this.completed = false,
  });

  final String id;
  final String title;
  final bool completed;

  MissionEntity copyWith({bool? completed}) => MissionEntity(
    id: id,
    title: title,
    completed: completed ?? this.completed,
  );
}
