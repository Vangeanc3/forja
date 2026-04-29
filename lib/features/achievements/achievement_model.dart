class Achievement {
  const Achievement({
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

  Achievement copyWith({bool? unlocked}) => Achievement(
        id: id,
        title: title,
        description: description,
        icon: icon,
        daysRequired: daysRequired,
        unlocked: unlocked ?? this.unlocked,
      );
}

const kAchievements = [
  Achievement(
    id: 'spark',
    title: 'Primeira Faísca',
    description: 'O início da forja',
    icon: '✨',
    daysRequired: 1,
  ),
  Achievement(
    id: 'iron',
    title: 'Ferro Aquecido',
    description: '1 semana resistindo',
    icon: '🔥',
    daysRequired: 7,
  ),
  Achievement(
    id: 'forming',
    title: 'Em Formação',
    description: '2 semanas na forja',
    icon: '⚒️',
    daysRequired: 14,
  ),
  Achievement(
    id: 'sword',
    title: 'Espada Moldada',
    description: '1 mês de disciplina',
    icon: '⚔️',
    daysRequired: 30,
  ),
  Achievement(
    id: 'blade',
    title: 'Lâmina Afiada',
    description: '2 meses inabalável',
    icon: '🗡️',
    daysRequired: 60,
  ),
  Achievement(
    id: 'forged',
    title: 'Forjado',
    description: '90 dias. Você virou aço.',
    icon: '🏆',
    daysRequired: 90,
  ),
];
