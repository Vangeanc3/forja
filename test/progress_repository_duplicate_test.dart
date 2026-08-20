import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:forja/core/constants.dart';
import 'package:forja/data/repositories/progress_repository.dart';
import 'package:forja/domain/entities/progress_area_entity.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() {
    hiveDirectory = Directory.systemTemp.createTempSync(
      'forja_duplicate_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await _openAndClear(ForjaBoxes.tasks);
  });

  test('duplica uma área com seus indicadores, histórico e tópicos', () async {
    final repository = ProgressRepository();
    await repository.addArea(title: 'Estudos PC/PA', description: 'Foco');

    final original = repository.getAll().single;
    await repository.addMetric(
      areaId: original.id,
      title: 'Língua Portuguesa',
      percent: 70,
      description: 'Gramática',
      note: 'Avaliação inicial',
      details: const [
        MetricDetailEntity(
          id: 'detail-1',
          title: 'Crase',
          description: 'Regras de crase',
          items: [
            MetricDetailEntity(
              id: 'detail-1-1',
              title: 'Exceções',
              description: 'Casos especiais',
            ),
          ],
        ),
      ],
    );

    final areaWithMetric = repository.getAll().single;
    final metric = areaWithMetric.metrics.single;

    await repository.duplicateArea(areaWithMetric.id);

    final areas = repository.getAll();
    expect(areas.length, 2);

    final duplicatedArea = areas.firstWhere((a) => a.id != areaWithMetric.id);
    expect(duplicatedArea.title, 'Estudos PC/PA (cópia)');
    expect(duplicatedArea.description, 'Foco');
    expect(duplicatedArea.id, isNot(areaWithMetric.id));

    expect(duplicatedArea.metrics.length, 1);
    final duplicatedMetric = duplicatedArea.metrics.single;
    expect(duplicatedMetric.title, 'Língua Portuguesa');
    expect(duplicatedMetric.percent, 70);
    expect(duplicatedMetric.id, isNot(metric.id));

    expect(duplicatedMetric.history.length, metric.history.length);
    expect(duplicatedMetric.history.last.percent, 70);
    expect(
      duplicatedMetric.history.map((h) => h.id).toSet().length,
      duplicatedMetric.history.length,
    );
    for (final checkpoint in duplicatedMetric.history) {
      expect(metric.history.map((h) => h.id), isNot(contains(checkpoint.id)));
    }

    expect(duplicatedMetric.details.single.title, 'Crase');
    expect(duplicatedMetric.details.single.id, isNot('detail-1'));
    expect(duplicatedMetric.details.single.items.single.title, 'Exceções');
    expect(
      duplicatedMetric.details.single.items.single.id,
      isNot('detail-1-1'),
    );

    // A área original permanece intacta.
    final untouchedOriginal = areas.firstWhere(
      (a) => a.id == areaWithMetric.id,
    );
    expect(untouchedOriginal.metrics.single.title, 'Língua Portuguesa');
    expect(untouchedOriginal.metrics.single.details.single.id, 'detail-1');
  });

  test('duplica um indicador dentro da mesma área, logo após o original', () async {
    final repository = ProgressRepository();
    await repository.addArea(title: 'Academia');
    final area = repository.getAll().single;

    await repository.addMetric(
      areaId: area.id,
      title: 'Força',
      percent: 40,
      note: 'Início',
    );
    await repository.addMetric(
      areaId: area.id,
      title: 'Resistência',
      percent: 60,
    );

    final areaWithMetrics = repository.getAll().single;
    final forcaMetric = areaWithMetrics.metrics.firstWhere(
      (m) => m.title == 'Força',
    );

    await repository.duplicateMetric(
      areaId: area.id,
      metricId: forcaMetric.id,
    );

    final updatedArea = repository.getAll().single;
    expect(updatedArea.metrics.length, 3);

    final titles = updatedArea.metrics.map((m) => m.title).toList();
    expect(titles[0], 'Força');
    expect(titles[1], 'Força (cópia)');
    expect(titles[2], 'Resistência');

    final duplicated = updatedArea.metrics[1];
    expect(duplicated.percent, 40);
    expect(duplicated.id, isNot(forcaMetric.id));
    expect(duplicated.history.length, forcaMetric.history.length);
    expect(duplicated.history.single.note, 'Início');
    expect(duplicated.history.single.id, isNot(forcaMetric.history.single.id));
  });

  test('duplicar área ou indicador inexistente não gera erro nem efeito', () async {
    final repository = ProgressRepository();

    await repository.duplicateArea('inexistente');
    expect(repository.getAll(), isEmpty);

    await repository.addArea(title: 'Sono');
    final area = repository.getAll().single;

    await repository.duplicateMetric(
      areaId: area.id,
      metricId: 'inexistente',
    );
    expect(repository.getAll().single.metrics, isEmpty);

    await repository.duplicateMetric(
      areaId: 'area-inexistente',
      metricId: 'qualquer',
    );
    expect(repository.getAll().length, 1);
  });
}

Future<void> _openAndClear(String boxName) async {
  if (!Hive.isBoxOpen(boxName)) {
    await Hive.openBox(boxName);
  }
  await Hive.box(boxName).clear();
}
