import 'package:forja/domain/entities/weekly_challenge_entity.dart';

class WeeklyChallengeModel extends WeeklyChallengeEntity {
  const WeeklyChallengeModel({
    required super.id,
    required super.title,
    required super.description,
  });

  factory WeeklyChallengeModel.fromEntity(WeeklyChallengeEntity entity) =>
      WeeklyChallengeModel(
        id: entity.id,
        title: entity.title,
        description: entity.description,
      );

  factory WeeklyChallengeModel.fromMap(Map<dynamic, dynamic> map) =>
      WeeklyChallengeModel(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
  };
}
