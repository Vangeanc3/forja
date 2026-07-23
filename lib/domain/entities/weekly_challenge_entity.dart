class WeeklyChallengeEntity {
  const WeeklyChallengeEntity({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

const List<WeeklyChallengeEntity> kWeeklyChallenges = [
  WeeklyChallengeEntity(
    id: 'social_media',
    title: '7 dias sem redes sociais após 22h',
    description: 'Desconecte-se para dormir melhor e retomar o foco.',
  ),
  WeeklyChallengeEntity(
    id: 'early_bird',
    title: 'Acorde antes das 6h todos os dias',
    description: 'Domine a manhã e você dominará o seu dia.',
  ),
  WeeklyChallengeEntity(
    id: 'exercise',
    title: '30 minutos de exercício por dia',
    description: 'Fortaleça seu corpo para fortalecer sua mente.',
  ),
  WeeklyChallengeEntity(
    id: 'no_junk_food',
    title: 'Sem junk food essa semana',
    description: 'Você é o que você come. Coma como um homem de valor.',
  ),
  WeeklyChallengeEntity(
    id: 'reading',
    title: 'Leia 10 páginas por dia',
    description: 'Conhecimento é a arma mais afiada do seu arsenal.',
  ),
];
