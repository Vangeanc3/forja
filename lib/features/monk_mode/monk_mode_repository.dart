import 'package:hive/hive.dart';
import '../../core/constants.dart';

class MonkModeRepository {
  Box get _box => Hive.box(ForjaBoxes.monkMode);

  bool get isActive => _box.get('is_active', defaultValue: false) as bool;

  List<String> get activeRestrictions => 
      _box.get('active_restrictions', defaultValue: <String>[]) as List<String>;

  Future<void> setMonkMode(bool active, List<String> restrictions) async {
    await _box.put('is_active', active);
    await _box.put('active_restrictions', restrictions);
  }
}

final kMonkRestrictions = [
  'Sem redes sociais',
  'Sem jogos',
  'Sem álcool',
  'Sem junk food',
  'Sem séries/filmes',
  'Acordar antes das 6h',
  'Exercício diário obrigatório',
];
