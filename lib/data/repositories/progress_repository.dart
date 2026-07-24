import 'package:hive/hive.dart';
import 'package:forja/data/models/progress_area_model.dart';
import 'package:forja/domain/entities/progress_area_entity.dart';

import '../../core/constants.dart';
import '../services/firebase_sync_service.dart';

const _deletedAreasKey = '_deleted_progress_areas';

class ProgressRepository {
  ProgressRepository({FirebaseSyncService? firebaseSync})
    : _firebaseSync = firebaseSync;

  final FirebaseSyncService? _firebaseSync;

  Box get _box => Hive.box(ForjaBoxes.tasks);

  List<ProgressAreaEntity> getAll() {
    final areas = _box.values
        .whereType<Map>()
        .where(_isAreaMap)
        .map(ProgressAreaModel.fromMap)
        .toList();

    areas.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return areas;
  }

  Future<void> addArea({required String title, String description = ''}) async {
    final now = DateTime.now();
    final area = ProgressAreaModel(
      id: _newId(),
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    await _box.put(area.id, area.toMap());
    await _syncArea(area);
  }

  Future<void> updateArea({
    required String id,
    required String title,
    String description = '',
  }) async {
    final area = _getArea(id);
    if (area == null) return;

    final updatedArea = area.copyWith(
      title: title,
      description: description,
      updatedAt: DateTime.now(),
    );

    await _box.put(id, updatedArea.toMap());
    await _syncArea(updatedArea);
  }

  Future<void> deleteArea(String id) async {
    final deletedAt = DateTime.now();
    await _box.delete(id);
    await _recordDeletedArea(id, deletedAt);
    await _syncAreaDeletion(id, deletedAt);
  }

  Future<void> addMetric({
    required String areaId,
    required String title,
    required int percent,
    String description = '',
    String note = '',
    List<MetricDetailEntity> details = const [],
  }) async {
    final area = _getArea(areaId);
    if (area == null) return;

    final now = DateTime.now();
    final id = _newId();
    final normalizedPercent = _clampPercent(percent);
    final metric = ProgressMetricModel(
      id: id,
      title: title,
      description: description,
      percent: normalizedPercent,
      createdAt: now,
      updatedAt: now,
      history: [
        SkillCheckpointModel(
          id: '$id-initial',
          percent: normalizedPercent,
          note: note.trim(),
          createdAt: now,
        ),
      ],
      details: details,
    );

    final updatedArea = area.copyWith(
      updatedAt: now,
      metrics: [...area.metrics, metric],
    );
    await _box.put(areaId, updatedArea.toMap());
    await _syncArea(updatedArea);
  }

  Future<void> updateMetric({
    required String areaId,
    required String metricId,
    required String title,
    required int percent,
    String description = '',
    String note = '',
    List<MetricDetailEntity> details = const [],
  }) async {
    final area = _getArea(areaId);
    if (area == null) return;

    final now = DateTime.now();
    final normalizedPercent = _clampPercent(percent);
    final metrics = area.metrics.map((metric) {
      if (metric.id != metricId) return metric;

      final shouldRecordCheckpoint =
          metric.percent != normalizedPercent || note.trim().isNotEmpty;
      final updatedHistory = shouldRecordCheckpoint
          ? [
              ...metric.history,
              SkillCheckpointModel(
                id: _newId(),
                percent: normalizedPercent,
                note: note.trim(),
                createdAt: now,
              ),
            ]
          : metric.history;

      return metric.copyWith(
        title: title,
        description: description,
        percent: normalizedPercent,
        updatedAt: now,
        history: updatedHistory,
        details: details,
      );
    }).toList();

    final updatedArea = area.copyWith(updatedAt: now, metrics: metrics);
    await _box.put(areaId, updatedArea.toMap());
    await _syncArea(updatedArea);
  }

  Future<void> deleteMetric({
    required String areaId,
    required String metricId,
  }) async {
    final area = _getArea(areaId);
    if (area == null) return;

    final metrics = area.metrics
        .where((metric) => metric.id != metricId)
        .toList();

    final updatedArea = area.copyWith(
      updatedAt: DateTime.now(),
      metrics: metrics,
    );
    await _box.put(areaId, updatedArea.toMap());
    await _syncArea(updatedArea);
  }

  Future<void> syncAll() async {
    for (final area in getAll()) {
      await _syncArea(area);
    }
    for (final entry in _deletedAreas.entries) {
      final deletedAt = _dateFrom(entry.value);
      if (deletedAt != null) {
        await _syncAreaDeletion(entry.key, deletedAt);
      }
    }
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> mergeRemote(List<FirebaseSyncDocument> documents) async {
    for (final document in documents) {
      final localArea = _getArea(document.id);
      final localDeletedAt = _dateFrom(_deletedAreas[document.id]);
      final remoteDeletedAt = _dateFrom(document.data['deletedAt']);

      if (remoteDeletedAt != null) {
        if (localArea == null || remoteDeletedAt.isAfter(localArea.updatedAt)) {
          await _box.delete(document.id);
          await _recordDeletedArea(document.id, remoteDeletedAt);
        } else {
          await _clearDeletedArea(document.id);
          await _syncArea(localArea);
        }
        continue;
      }

      if (!_isAreaMap(document.data)) continue;

      final remoteArea = ProgressAreaModel.fromMap(document.data);
      if (localDeletedAt != null &&
          localDeletedAt.isAfter(remoteArea.updatedAt)) {
        await _syncAreaDeletion(document.id, localDeletedAt);
        continue;
      }

      if (localArea == null) {
        await _clearDeletedArea(document.id);
        await _putArea(remoteArea);
        continue;
      }

      final merged = _mergeArea(localArea, remoteArea);
      await _clearDeletedArea(document.id);
      await _putArea(merged);
    }

    await syncAll();
  }

  ProgressAreaModel? _getArea(String id) {
    final raw = _box.get(id);
    if (raw is! Map || !_isAreaMap(raw)) return null;
    return ProgressAreaModel.fromMap(raw);
  }

  int _clampPercent(int percent) => percent.clamp(0, 100).toInt();

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _syncArea(ProgressAreaEntity area) =>
      _firebaseSync?.setDocument('progressAreas', area.id, {
        ...ProgressAreaModel.fromEntity(area).toMap(),
        'deletedAt': null,
      }) ??
      Future.value();

  Future<void> _syncAreaDeletion(String id, DateTime deletedAt) =>
      _firebaseSync?.setDocument('progressAreas', id, {
        'id': id,
        'deletedAt': deletedAt.toIso8601String(),
      }) ??
      Future.value();

  Future<void> _putArea(ProgressAreaEntity area) {
    return _box.put(area.id, ProgressAreaModel.fromEntity(area).toMap());
  }

  Map<String, String> get _deletedAreas {
    final raw = _box.get(_deletedAreasKey);
    if (raw is! Map) return {};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  Future<void> _recordDeletedArea(String id, DateTime deletedAt) async {
    final deletedAreas = _deletedAreas;
    deletedAreas[id] = deletedAt.toIso8601String();
    await _box.put(_deletedAreasKey, deletedAreas);
  }

  Future<void> _clearDeletedArea(String id) async {
    final deletedAreas = _deletedAreas;
    if (!deletedAreas.containsKey(id)) return;
    deletedAreas.remove(id);
    await _box.put(_deletedAreasKey, deletedAreas);
  }

  bool _isAreaMap(Map<dynamic, dynamic> map) =>
      map['deletedAt'] == null &&
      map['id'] != null &&
      map['title'] != null &&
      map['createdAt'] != null;

  ProgressAreaModel _mergeArea(
    ProgressAreaEntity local,
    ProgressAreaEntity remote,
  ) {
    final localWins = !remote.updatedAt.isAfter(local.updatedAt);
    final metrics = _mergeMetrics(local.metrics, remote.metrics);
    final latestMetricDate = metrics
        .map((metric) => metric.updatedAt)
        .fold<DateTime?>(null, _latest);
    final updatedAt = _latest(
      _latest(local.updatedAt, remote.updatedAt),
      latestMetricDate,
    )!;

    return ProgressAreaModel(
      id: local.id,
      title: _chooseText(
        localWins ? local.title : remote.title,
        localWins ? remote.title : local.title,
      ),
      description: _chooseText(
        localWins ? local.description : remote.description,
        localWins ? remote.description : local.description,
      ),
      createdAt: _earliest(local.createdAt, remote.createdAt),
      updatedAt: updatedAt,
      metrics: metrics,
    );
  }

  List<ProgressMetricEntity> _mergeMetrics(
    List<ProgressMetricEntity> local,
    List<ProgressMetricEntity> remote,
  ) {
    final ids = {
      ...local.map((metric) => metric.id),
      ...remote.map((metric) => metric.id),
    };
    final merged = <ProgressMetricEntity>[];

    for (final id in ids) {
      final localMetric = _findMetric(local, id);
      final remoteMetric = _findMetric(remote, id);
      if (localMetric != null && remoteMetric != null) {
        merged.add(_mergeMetric(localMetric, remoteMetric));
      } else if (localMetric != null) {
        merged.add(localMetric);
      } else if (remoteMetric != null) {
        merged.add(remoteMetric);
      }
    }

    merged.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return merged;
  }

  ProgressMetricEntity _mergeMetric(
    ProgressMetricEntity local,
    ProgressMetricEntity remote,
  ) {
    final localWins = !remote.updatedAt.isAfter(local.updatedAt);
    final winner = localWins ? local : remote;
    final fallback = localWins ? remote : local;

    return ProgressMetricModel(
      id: local.id,
      title: _chooseText(winner.title, fallback.title),
      description: _chooseText(winner.description, fallback.description),
      percent: winner.percent,
      createdAt: _earliest(local.createdAt, remote.createdAt),
      updatedAt: _latest(local.updatedAt, remote.updatedAt)!,
      history: _mergeHistory(local.history, remote.history),
      details: winner.details,
    );
  }

  List<SkillCheckpointEntity> _mergeHistory(
    List<SkillCheckpointEntity> local,
    List<SkillCheckpointEntity> remote,
  ) {
    final byKey = <String, SkillCheckpointEntity>{};
    for (final checkpoint in [...local, ...remote]) {
      byKey[_checkpointKey(checkpoint)] = checkpoint;
    }

    final merged = byKey.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }

  ProgressMetricEntity? _findMetric(
    List<ProgressMetricEntity> metrics,
    String id,
  ) {
    for (final metric in metrics) {
      if (metric.id == id) return metric;
    }
    return null;
  }

  String _checkpointKey(SkillCheckpointEntity checkpoint) =>
      '${checkpoint.id}:${checkpoint.createdAt.microsecondsSinceEpoch}';

  String _chooseText(String preferred, String fallback) =>
      preferred.trim().isEmpty ? fallback : preferred;

  DateTime _earliest(DateTime first, DateTime second) =>
      first.isBefore(second) ? first : second;

  DateTime? _latest(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isAfter(second) ? first : second;
  }

  DateTime? _dateFrom(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
