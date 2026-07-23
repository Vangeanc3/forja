import 'package:forja/domain/entities/achievement_entity.dart';

class AchievementModel extends AchievementEntity {
  const AchievementModel({
    required super.id,
    required super.title,
    required super.description,
    required super.icon,
    required super.daysRequired,
    super.unlocked = false,
  });

  factory AchievementModel.fromEntity(AchievementEntity entity) =>
      AchievementModel(
        id: entity.id,
        title: entity.title,
        description: entity.description,
        icon: entity.icon,
        daysRequired: entity.daysRequired,
        unlocked: entity.unlocked,
      );

  @override
  AchievementModel copyWith({bool? unlocked}) => AchievementModel(
    id: id,
    title: title,
    description: description,
    icon: icon,
    daysRequired: daysRequired,
    unlocked: unlocked ?? this.unlocked,
  );
}
