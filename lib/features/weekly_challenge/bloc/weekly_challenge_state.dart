import 'package:equatable/equatable.dart';
import 'package:forja/domain/entities/weekly_challenge_entity.dart';

class WeeklyChallengeState extends Equatable {
  const WeeklyChallengeState({required this.challenge, required this.accepted});

  final WeeklyChallengeEntity challenge;
  final bool accepted;

  @override
  List<Object?> get props => [challenge.id, accepted];
}
