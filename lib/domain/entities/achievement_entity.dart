class AchievementEntity {
  const AchievementEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.daysRequired,
    this.unlocked = false,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final int daysRequired;
  final bool unlocked;

  AchievementEntity copyWith({bool? unlocked}) => AchievementEntity(
    id: id,
    title: title,
    description: description,
    icon: icon,
    daysRequired: daysRequired,
    unlocked: unlocked ?? this.unlocked,
  );
}

const List<AchievementEntity> kAchievements = [
  AchievementEntity(
    id: 'spark',
    title: 'Primeira Faísca',
    description: 'O início da forja',
    icon: '✨',
    daysRequired: 1,
  ),
  AchievementEntity(
    id: 'iron',
    title: 'Ferro Aquecido',
    description: '1 semana resistindo',
    icon: '🔥',
    daysRequired: 7,
  ),
  AchievementEntity(
    id: 'forming',
    title: 'Em Formação',
    description: '2 semanas na forja',
    icon: '⚒️',
    daysRequired: 14,
  ),
  AchievementEntity(
    id: 'sword',
    title: 'Espada Moldada',
    description: '1 mês de disciplina',
    icon: '⚔️',
    daysRequired: 30,
  ),
  AchievementEntity(
    id: 'blade',
    title: 'Lâmina Afiada',
    description: '2 meses inabalável',
    icon: '🗡️',
    daysRequired: 60,
  ),
  AchievementEntity(
    id: 'forged',
    title: 'Forjado',
    description: '90 dias. Você virou aço.',
    icon: '🏆',
    daysRequired: 90,
  ),
];
