import 'package:forja/domain/entities/progress_area_entity.dart';

class SkillCheckpointModel extends SkillCheckpointEntity {
  const SkillCheckpointModel({
    required super.id,
    required super.percent,
    required super.createdAt,
    super.note = '',
  });

  factory SkillCheckpointModel.fromEntity(SkillCheckpointEntity entity) =>
      SkillCheckpointModel(
        id: entity.id,
        percent: entity.percent,
        note: entity.note,
        createdAt: entity.createdAt,
      );

  factory SkillCheckpointModel.fromMap(Map<dynamic, dynamic> map) =>
      SkillCheckpointModel(
        id: map['id'] as String,
        percent: _normalizePercent(map['percent']),
        note: map['note'] as String? ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'percent': percent,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };
}

class MetricDetailItemModel extends MetricDetailItemEntity {
  const MetricDetailItemModel({
    required super.id,
    required super.title,
    required super.description,
  });

  factory MetricDetailItemModel.fromEntity(MetricDetailItemEntity entity) =>
      MetricDetailItemModel(
        id: entity.id,
        title: entity.title,
        description: entity.description,
      );

  factory MetricDetailItemModel.fromMap(Map<dynamic, dynamic> map) =>
      MetricDetailItemModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
      };
}

class MetricDetailModel extends MetricDetailEntity {
  const MetricDetailModel({
    required super.id,
    required super.title,
    required super.description,
    super.items = const [],
  });

  factory MetricDetailModel.fromEntity(MetricDetailEntity entity) =>
      MetricDetailModel(
        id: entity.id,
        title: entity.title,
        description: entity.description,
        items: entity.items.map(MetricDetailItemModel.fromEntity).toList(),
      );

  factory MetricDetailModel.fromMap(Map<dynamic, dynamic> map) {
    final rawItems = (map['items'] as List?) ?? const [];
    final items = rawItems
        .map((entry) => MetricDetailItemModel.fromMap(entry as Map))
        .toList();

    return MetricDetailModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      items: items,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'items': items.map((e) => (e as MetricDetailItemModel).toMap()).toList(),
      };
}

class ProgressMetricModel extends ProgressMetricEntity {
  const ProgressMetricModel({
    required super.id,
    required super.title,
    required super.percent,
    required super.createdAt,
    required super.updatedAt,
    super.description = '',
    super.history = const [],
    super.details = const [],
  });

  factory ProgressMetricModel.fromEntity(ProgressMetricEntity entity) =>
      ProgressMetricModel(
        id: entity.id,
        title: entity.title,
        description: entity.description,
        percent: entity.percent,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        history: entity.history.map(SkillCheckpointModel.fromEntity).toList(),
        details: entity.details.map(MetricDetailModel.fromEntity).toList(),
      );

  factory ProgressMetricModel.fromMap(Map<dynamic, dynamic> map) {
    final createdAt = DateTime.parse(map['createdAt'] as String);
    final percent = _normalizePercent(map['percent']);
    final rawHistory = (map['history'] as List?) ?? const [];
    final history = rawHistory
        .map((entry) => SkillCheckpointModel.fromMap(entry as Map))
        .toList();
    final rawDetails = (map['details'] as List?) ?? const [];
    final details = rawDetails
        .map((entry) => MetricDetailModel.fromMap(entry as Map))
        .toList();

    return ProgressMetricModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description:
          map['description'] as String? ?? map['notes'] as String? ?? '',
      percent: percent,
      createdAt: createdAt,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : createdAt,
      history: history.isEmpty
          ? [
              SkillCheckpointModel(
                id: '${map['id']}-initial',
                percent: percent,
                createdAt: createdAt,
              ),
            ]
          : history,
      details: details,
    );
  }

  @override
  ProgressMetricModel copyWith({
    String? title,
    String? description,
    int? percent,
    DateTime? updatedAt,
    List<SkillCheckpointEntity>? history,
    List<MetricDetailEntity>? details,
  }) {
    return ProgressMetricModel(
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'percent': percent,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'history': history
        .map((entry) => SkillCheckpointModel.fromEntity(entry).toMap())
        .toList(),
    'details': details
        .map((e) => MetricDetailModel.fromEntity(e).toMap())
        .toList(),
  };
}

class ProgressAreaModel extends ProgressAreaEntity {
  const ProgressAreaModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    super.description = '',
    super.metrics = const [],
  });

  factory ProgressAreaModel.fromEntity(ProgressAreaEntity entity) =>
      ProgressAreaModel(
        id: entity.id,
        title: entity.title,
        description: entity.description,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        metrics: entity.metrics.map(ProgressMetricModel.fromEntity).toList(),
      );

  factory ProgressAreaModel.fromMap(Map<dynamic, dynamic> map) {
    final createdAt = DateTime.parse(map['createdAt'] as String);

    final rawMetrics = map['metrics'] is List
        ? map['metrics'] as List
        : map['subjects'] is List
        ? map['subjects'] as List
        : null;

    if (rawMetrics != null) {
      return ProgressAreaModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        createdAt: createdAt,
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : createdAt,
        metrics: rawMetrics
            .map((metric) => ProgressMetricModel.fromMap(metric as Map))
            .toList(),
      );
    }

    return ProgressAreaModel._fromLegacyMap(map, createdAt);
  }

  factory ProgressAreaModel._fromLegacyMap(
    Map<dynamic, dynamic> map,
    DateTime createdAt,
  ) {
    final id = map['id'] as String;

    if (map['percent'] != null) {
      final metric = ProgressMetricModel.fromMap(map);
      return ProgressAreaModel(
        id: id,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        createdAt: createdAt,
        updatedAt: metric.updatedAt,
        metrics: [metric],
      );
    }

    final rawItems = (map['items'] as List?) ?? const [];
    final metrics = rawItems.map((item) {
      final itemMap = item as Map;
      final completed = itemMap['completed'] as bool? ?? false;
      final itemCreatedAt = itemMap['createdAt'] != null
          ? DateTime.parse(itemMap['createdAt'] as String)
          : createdAt;
      return ProgressMetricModel(
        id: itemMap['id'] as String,
        title: itemMap['title'] as String,
        description: itemMap['notes'] as String? ?? '',
        percent: completed ? 100 : 0,
        createdAt: itemCreatedAt,
        updatedAt: itemMap['completedAt'] != null
            ? DateTime.parse(itemMap['completedAt'] as String)
            : itemCreatedAt,
        history: [
          SkillCheckpointModel(
            id: '${itemMap['id']}-initial',
            percent: completed ? 100 : 0,
            createdAt: itemCreatedAt,
          ),
        ],
      );
    }).toList();

    return ProgressAreaModel(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : createdAt,
      metrics: metrics,
    );
  }

  @override
  ProgressAreaModel copyWith({
    String? title,
    String? description,
    DateTime? updatedAt,
    List<ProgressMetricEntity>? metrics,
  }) => ProgressAreaModel(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    metrics: metrics ?? this.metrics,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'metrics': metrics
        .map((metric) => ProgressMetricModel.fromEntity(metric).toMap())
        .toList(),
  };
}

int _normalizePercent(Object? value) {
  if (value is int) return value.clamp(0, 100).toInt();
  if (value is double) return value.round().clamp(0, 100).toInt();
  if (value is String) {
    return (int.tryParse(value) ?? 0).clamp(0, 100).toInt();
  }
  return 0;
}
