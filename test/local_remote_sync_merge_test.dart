import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:forja/core/constants.dart';
import 'package:forja/data/models/progress_area_model.dart';
import 'package:forja/data/repositories/progress_repository.dart';
import 'package:forja/data/repositories/settings_repository.dart';
import 'package:forja/data/services/firebase_sync_service.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() {
    hiveDirectory = Directory.systemTemp.createTempSync('forja_sync_test_');
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await _openAndClear(ForjaBoxes.settings);
    await _openAndClear(ForjaBoxes.tasks);
  });

  test(
    'preenche settings locais quando o remoto tem onboarding completo',
    () async {
      final repository = SettingsRepository();

      await repository.mergeRemote(
        const FirebaseSyncDocument(
          id: 'current',
          data: {
            'onboardingDone': true,
            'userName': 'Ismael',
            'userMode': ForjaMode.monge,
            'userReason': 'Disciplina',
            'notificationsEnabled': false,
            'notificationHour': 6,
            'riskHours': ['22:00'],
            'userGoal': '90 dias limpo',
          },
        ),
      );

      final snapshot = repository.snapshot();
      expect(snapshot.onboardingDone, isTrue);
      expect(snapshot.userName, 'Ismael');
      expect(snapshot.userMode, ForjaMode.monge);
      expect(snapshot.notificationsEnabled, isFalse);
      expect(snapshot.notificationHour, 6);
      expect(snapshot.riskHours, ['22:00']);
      expect(snapshot.userGoal, '90 dias limpo');
    },
  );

  test(
    'mescla progress areas por updatedAt e respeita tombstone local',
    () async {
      final repository = ProgressRepository();
      await repository.addArea(title: 'Local', description: 'Atual');

      final local = repository.getAll().single;
      final olderRemote = ProgressAreaModel(
        id: local.id,
        title: 'Remoto antigo',
        description: 'Nao deve vencer',
        createdAt: local.createdAt,
        updatedAt: local.updatedAt.subtract(const Duration(days: 1)),
      );

      await repository.mergeRemote([
        FirebaseSyncDocument(id: local.id, data: olderRemote.toMap()),
      ]);

      expect(repository.getAll().single.title, 'Local');

      final newerRemote = ProgressAreaModel(
        id: local.id,
        title: 'Remoto novo',
        description: 'Deve vencer',
        createdAt: local.createdAt,
        updatedAt: local.updatedAt.add(const Duration(days: 1)),
      );

      await repository.mergeRemote([
        FirebaseSyncDocument(id: local.id, data: newerRemote.toMap()),
      ]);

      expect(repository.getAll().single.title, 'Remoto novo');

      await repository.deleteArea(local.id);
      await repository.mergeRemote([
        FirebaseSyncDocument(id: local.id, data: olderRemote.toMap()),
      ]);

      expect(repository.getAll(), isEmpty);
    },
  );
}

Future<void> _openAndClear(String boxName) async {
  if (!Hive.isBoxOpen(boxName)) {
    await Hive.openBox(boxName);
  }
  await Hive.box(boxName).clear();
}
