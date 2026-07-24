import 'package:hive/hive.dart';
import 'package:forja/data/models/monk_mode_model.dart';

import '../../core/constants.dart';
import '../services/firebase_sync_service.dart';

class MonkModeRepository {
  MonkModeRepository({FirebaseSyncService? firebaseSync})
    : _firebaseSync = firebaseSync;

  final FirebaseSyncService? _firebaseSync;

  Box get _box => Hive.box(ForjaBoxes.monkMode);

  bool get isActive => _box.get('is_active', defaultValue: false) as bool;

  List<String> get activeRestrictions =>
      List<String>.from(_box.get('active_restrictions', defaultValue: <String>[]) as Iterable);

  MonkModeModel snapshot() => MonkModeModel(
    active: isActive,
    restrictions: List.unmodifiable(activeRestrictions),
  );

  Future<void> setMonkMode(bool active, List<String> restrictions) async {
    await _box.put('is_active', active);
    await _box.put('active_restrictions', restrictions);
    await syncCurrent();
  }

  Future<void> syncCurrent() =>
      _firebaseSync?.setDocument('monkMode', 'current', snapshot().toMap()) ??
      Future.value();

  Future<void> mergeRemote(FirebaseSyncDocument? document) async {
    if (document == null) {
      await syncCurrent();
      return;
    }

    final local = snapshot();
    final remote = MonkModeModel.fromMap(document.data);
    final restrictions = {
      ...local.restrictions,
      ...remote.restrictions,
    }.toList(growable: false);

    await _box.put('is_active', local.active || remote.active);
    await _box.put('active_restrictions', restrictions);
    await syncCurrent();
  }
}
