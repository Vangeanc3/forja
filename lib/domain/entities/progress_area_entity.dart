class SkillCheckpointEntity {
  const SkillCheckpointEntity({
    required this.id,
    required this.percent,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final int percent;
  final String note;
  final DateTime createdAt;
}

enum MetricDetailType {
  topic('Tópico'),
  concept('Conceito'),
  rule('Regra'),
  example('Exemplo'),
  note('Observação'),
  subtopic('Sub-tópico'),
  other('Outro');

  const MetricDetailType(this.label);
  final String label;
}

class MetricDetailEntity {
  const MetricDetailEntity({
    required this.id,
    required this.title,
    required this.description,
    this.type = MetricDetailType.topic,
    this.items = const [],
  });

  final String id;
  final String title;
  final String description;
  final MetricDetailType type;
  final List<MetricDetailEntity> items;

  MetricDetailEntity copyWith({
    String? title,
    String? description,
    MetricDetailType? type,
    List<MetricDetailEntity>? items,
  }) {
    return MetricDetailEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      items: items ?? this.items,
    );
  }
}

class ProgressMetricEntity {
  const ProgressMetricEntity({
    required this.id,
    required this.title,
    required this.percent,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.history = const [],
    this.details = const [],
  });

  final String id;
  final String title;
  final String description;
  final int percent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SkillCheckpointEntity> history;
  final List<MetricDetailEntity> details;

  double get progress => percent / 100;

  int get evolution {
    if (history.isEmpty) return 0;
    return percent - history.first.percent;
  }

  String get statusLabel {
    if (percent >= 90) return 'Dominado';
    if (percent >= 75) return 'Forte';
    if (percent >= 50) return 'Bom';
    if (percent >= 25) return 'Base';
    return 'Inicial';
  }

  ProgressMetricEntity copyWith({
    String? title,
    String? description,
    int? percent,
    DateTime? updatedAt,
    List<SkillCheckpointEntity>? history,
    List<MetricDetailEntity>? details,
  }) {
    return ProgressMetricEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      percent: percent ?? this.percent,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
      details: details ?? this.details,
    );
  }
}

class ProgressAreaEntity {
  const ProgressAreaEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.metrics = const [],
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProgressMetricEntity> metrics;

  int get averagePercent {
    if (metrics.isEmpty) return 0;
    final total = metrics.fold<int>(0, (sum, metric) => sum + metric.percent);
    return (total / metrics.length).round();
  }

  double get progress => averagePercent / 100;

  ProgressMetricEntity? get strongestMetric {
    if (metrics.isEmpty) return null;

    var strongest = metrics.first;

    for (final metric in metrics.skip(1)) {
      if (metric.percent > strongest.percent) {
        strongest = metric;
      }
    }

    return strongest;
  }

  ProgressMetricEntity? get weakestMetric {
    if (metrics.isEmpty) return null;

    var weakest = metrics.first;

    for (final metric in metrics.skip(1)) {
      if (metric.percent < weakest.percent) {
        weakest = metric;
      }
    }

    return weakest;
  }

  ProgressAreaEntity copyWith({
    String? title,
    String? description,
    DateTime? updatedAt,
    List<ProgressMetricEntity>? metrics,
  }) => ProgressAreaEntity(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    metrics: metrics ?? this.metrics,
  );
}
