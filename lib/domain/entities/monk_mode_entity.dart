const kMonkRestrictions = [
  'Sem redes sociais',
  'Sem jogos',
  'Sem álcool',
  'Sem junk food',
  'Sem séries/filmes',
  'Acordar antes das 6h',
  'Exercício diário obrigatório',
];

class MonkModeEntity {
  const MonkModeEntity({required this.active, required this.restrictions});

  final bool active;
  final List<String> restrictions;
}
