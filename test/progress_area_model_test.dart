import 'package:flutter_test/flutter_test.dart';
import 'package:forja/data/models/progress_area_model.dart';
import 'package:forja/domain/entities/progress_area_entity.dart';

void main() {
  test('calcula media da area a partir dos indicadores', () {
    final area = ProgressAreaEntity(
      id: 'area-1',
      title: 'Estudos PC/PA',
      createdAt: DateTime(2026, 7, 21),
      updatedAt: DateTime(2026, 7, 22),
      metrics: [
        ProgressMetricEntity(
          id: 'metric-1',
          title: 'Lingua Portuguesa',
          percent: 70,
          createdAt: DateTime(2026, 7, 21),
          updatedAt: DateTime(2026, 7, 21),
        ),
        ProgressMetricEntity(
          id: 'metric-2',
          title: 'Direito Constitucional',
          percent: 90,
          createdAt: DateTime(2026, 7, 21),
          updatedAt: DateTime(2026, 7, 22),
        ),
      ],
    );

    expect(area.averagePercent, 80);
    expect(area.strongestMetric?.title, 'Direito Constitucional');
    expect(area.weakestMetric?.title, 'Lingua Portuguesa');
  });

  test('calcula evolucao de um indicador', () {
    final metric = ProgressMetricEntity(
      id: 'metric-1',
      title: 'Lingua Portuguesa',
      percent: 80,
      createdAt: DateTime(2026, 7, 21),
      updatedAt: DateTime(2026, 7, 22),
      history: [
        SkillCheckpointEntity(
          id: 'checkpoint-1',
          percent: 70,
          createdAt: DateTime(2026, 7, 21),
        ),
        SkillCheckpointEntity(
          id: 'checkpoint-2',
          percent: 80,
          createdAt: DateTime(2026, 7, 22),
        ),
      ],
    );

    expect(metric.progress, 0.8);
    expect(metric.evolution, 10);
    expect(metric.statusLabel, 'Forte');
  });

  test('preserva dados ao converter área para map', () {
    final original = ProgressAreaModel.fromEntity(
      ProgressAreaEntity(
        id: 'area-1',
        title: 'Estudos PC/PA',
        description: 'Preparacao para concurso',
        createdAt: DateTime(2026, 7, 21),
        updatedAt: DateTime(2026, 7, 23),
        metrics: [
          ProgressMetricEntity(
            id: 'metric-1',
            title: 'Direito Constitucional',
            description: 'Controle de constitucionalidade',
            percent: 65,
            createdAt: DateTime(2026, 7, 21),
            updatedAt: DateTime(2026, 7, 23),
            history: [
              SkillCheckpointEntity(
                id: 'checkpoint-1',
                percent: 50,
                note: 'Primeira avaliacao',
                createdAt: DateTime(2026, 7, 21),
              ),
              SkillCheckpointEntity(
                id: 'checkpoint-2',
                percent: 65,
                note: 'Depois de simulado',
                createdAt: DateTime(2026, 7, 23),
              ),
            ],
          ),
        ],
      ),
    );

    final restored = ProgressAreaModel.fromMap(original.toMap());

    expect(restored.id, original.id);
    expect(restored.title, original.title);
    expect(restored.description, original.description);
    expect(restored.averagePercent, 65);
    expect(restored.metrics.single.history.last.note, 'Depois de simulado');
  });
}
