import 'package:hive/hive.dart';
import '../../core/constants.dart';

class WeeklyChallenge {
  final String id;
  final String title;
  final String description;

  WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
  });
}

final kWeeklyChallenges = [
  WeeklyChallenge(
    id: 'social_media',
    title: '7 dias sem redes sociais após 22h',
    description: 'Desconecte-se para dormir melhor e retomar o foco.',
  ),
  WeeklyChallenge(
    id: 'early_bird',
    title: 'Acorde antes das 6h todos os dias',
    description: 'Domine a manhã e você dominará o seu dia.',
  ),
  WeeklyChallenge(
    id: 'exercise',
    title: '30 minutos de exercício por dia',
    description: 'Fortaleça seu corpo para fortalecer sua mente.',
  ),
  WeeklyChallenge(
    id: 'no_junk_food',
    title: 'Sem junk food essa semana',
    description: 'Você é o que você come. Coma como um homem de valor.',
  ),
  WeeklyChallenge(
    id: 'reading',
    title: 'Leia 10 páginas por dia',
    description: 'Conhecimento é a arma mais afiada do seu arsenal.',
  ),
];

class WeeklyChallengeRepository {
  Box get _box => Hive.box(ForjaBoxes.weeklyChallenge);

  WeeklyChallenge getCurrentChallenge() {
    final now = DateTime.now();
    // Muda o desafio baseado na semana do ano (aproximado)
    final weekIndex = (now.millisecondsSinceEpoch / (1000 * 60 * 60 * 24 * 7)).floor();
    return kWeeklyChallenges[weekIndex % kWeeklyChallenges.length];
  }

  bool isChallengeAccepted() {
    final lastDateRaw = _box.get(ForjaStorage.lastChallengeDateKey) as String?;
    if (lastDateRaw == null) return false;
    
    final lastDate = DateTime.parse(lastDateRaw);
    final now = DateTime.now();
    
    // Se for o mesmo dia (ou mesma semana, mas simplificado para o dia/mês atual para evitar resets bruscos)
    // Vamos considerar que o desafio é aceito se foi marcado como tal recentemente
    return _box.get(ForjaStorage.acceptedChallengeKey, defaultValue: false) as bool;
  }

  Future<void> acceptChallenge(bool accepted) async {
    await _box.put(ForjaStorage.acceptedChallengeKey, accepted);
    await _box.put(ForjaStorage.lastChallengeDateKey, DateTime.now().toIso8601String());
  }

  // Verifica se o desafio mudou para resetar o status de aceito
  void checkAndResetIfNeeded() {
    final lastDateRaw = _box.get(ForjaStorage.lastChallengeDateKey) as String?;
    if (lastDateRaw == null) return;
    
    final lastDate = DateTime.parse(lastDateRaw);
    final now = DateTime.now();
    
    // Simplificação: se mudou a semana (baseado no índice)
    final lastWeekIndex = (lastDate.millisecondsSinceEpoch / (1000 * 60 * 60 * 24 * 7)).floor();
    final currentWeekIndex = (now.millisecondsSinceEpoch / (1000 * 60 * 60 * 24 * 7)).floor();
    
    if (currentWeekIndex > lastWeekIndex) {
      _box.put(ForjaStorage.acceptedChallengeKey, false);
    }
  }
}
