import 'package:forja/domain/entities/progress_area_entity.dart';

abstract final class MetricDetailTree {
  static MetricDetailEntity? findById(
    List<MetricDetailEntity> details,
    String id,
  ) {
    for (final detail in details) {
      if (detail.id == id) return detail;
      final nested = findById(detail.items, id);
      if (nested != null) return nested;
    }

    return null;
  }

  static bool containsId(List<MetricDetailEntity> details, String id) =>
      findById(details, id) != null;

  static bool deepEquals(
    List<MetricDetailEntity> first,
    List<MetricDetailEntity> second,
  ) {
    if (first.length != second.length) return false;

    for (var index = 0; index < first.length; index++) {
      if (!_detailEquals(first[index], second[index])) return false;
    }

    return true;
  }

  static List<MetricDetailEntity> groupIntoParent({
    required List<MetricDetailEntity> details,
    required MetricDetailEntity parent,
    required Set<String> selectedIds,
    int? index,
  }) {
    if (selectedIds.isEmpty) return List.of(details);
    if (selectedIds.contains(parent.id)) {
      throw ArgumentError('O tópico pai não pode estar entre os selecionados.');
    }

    final removed = _removeByIds(details, selectedIds);
    final removedIds = removed.removed.map((detail) => detail.id).toSet();
    final missingIds = selectedIds.difference(removedIds);
    if (missingIds.isNotEmpty) {
      throw StateError('Tópicos não encontrados: ${missingIds.join(', ')}');
    }

    final groupedParent = parent.copyWith(
      items: [...parent.items, ...removed.removed],
    );

    return _insertAt(removed.details, groupedParent, index);
  }

  static List<MetricDetailEntity> move({
    required List<MetricDetailEntity> details,
    required String detailId,
    required String? parentId,
    int? index,
  }) {
    if (parentId == detailId) {
      throw ArgumentError('Um tópico não pode ser movido para dentro dele.');
    }

    final detail = findById(details, detailId);
    if (detail == null) {
      throw StateError('Tópico não encontrado: $detailId');
    }

    if (parentId != null && containsId(detail.items, parentId)) {
      throw ArgumentError(
        'Um tópico não pode ser movido para dentro de um sub-tópico dele.',
      );
    }

    final removed = _removeByIds(details, {detailId});
    final moved = removed.removed.single;

    if (parentId == null) {
      return _insertAt(removed.details, moved, index);
    }

    final inserted = _insertUnderParent(
      removed.details,
      parentId,
      moved,
      index,
    );
    if (!inserted.inserted) {
      throw StateError('Destino não encontrado: $parentId');
    }

    return inserted.details;
  }

  static List<MetricDetailEntity> moveMany({
    required List<MetricDetailEntity> details,
    required Set<String> detailIds,
    required String? parentId,
    int? index,
  }) {
    if (detailIds.isEmpty) return List.of(details);
    if (parentId != null && detailIds.contains(parentId)) {
      throw ArgumentError('O destino não pode estar entre os tópicos movidos.');
    }

    for (final detailId in detailIds) {
      final detail = findById(details, detailId);
      if (detail == null) {
        throw StateError('Tópico não encontrado: $detailId');
      }

      if (parentId != null && containsId(detail.items, parentId)) {
        throw ArgumentError(
          'Um tópico não pode ser movido para dentro de um sub-tópico dele.',
        );
      }
    }

    final removed = _removeByIds(details, detailIds);
    final removedIds = removed.removed.map((detail) => detail.id).toSet();
    final missingIds = detailIds.difference(removedIds);
    if (missingIds.isNotEmpty) {
      throw StateError('Tópicos não encontrados: ${missingIds.join(', ')}');
    }

    if (parentId == null) {
      return _insertManyAt(removed.details, removed.removed, index);
    }

    final inserted = _insertManyUnderParent(
      removed.details,
      parentId,
      removed.removed,
      index,
    );
    if (!inserted.inserted) {
      throw StateError('Destino não encontrado: $parentId');
    }

    return inserted.details;
  }

  static List<MetricDetailEntity> replace({
    required List<MetricDetailEntity> details,
    required String detailId,
    required MetricDetailEntity replacement,
  }) {
    final result = _replaceInList(details, detailId, replacement);
    if (!result.changed) {
      throw StateError('Tópico não encontrado: $detailId');
    }

    return result.details;
  }

  static ({List<MetricDetailEntity> details, MetricDetailEntity removed})
  remove({
    required List<MetricDetailEntity> details,
    required String detailId,
  }) {
    final result = _removeByIds(details, {detailId});
    if (result.removed.isEmpty) {
      throw StateError('Tópico não encontrado: $detailId');
    }

    return (details: result.details, removed: result.removed.single);
  }

  static List<MetricDetailEntity> ungroup({
    required List<MetricDetailEntity> details,
    required String parentId,
  }) {
    final result = _ungroupInList(details, parentId);
    if (!result.changed) {
      throw StateError('Tópico não encontrado: $parentId');
    }

    return result.details;
  }

  static bool _detailEquals(
    MetricDetailEntity first,
    MetricDetailEntity second,
  ) {
    return first.id == second.id &&
        first.title == second.title &&
        first.description == second.description &&
        first.type == second.type &&
        deepEquals(first.items, second.items);
  }

  static ({List<MetricDetailEntity> details, List<MetricDetailEntity> removed})
  _removeByIds(List<MetricDetailEntity> details, Set<String> ids) {
    final remaining = <MetricDetailEntity>[];
    final removed = <MetricDetailEntity>[];

    for (final detail in details) {
      if (ids.contains(detail.id)) {
        removed.add(detail);
        continue;
      }

      final nested = _removeByIds(detail.items, ids);
      removed.addAll(nested.removed);
      remaining.add(
        nested.removed.isEmpty
            ? detail
            : detail.copyWith(items: nested.details),
      );
    }

    return (details: remaining, removed: removed);
  }

  static List<MetricDetailEntity> _insertAt(
    List<MetricDetailEntity> details,
    MetricDetailEntity detail,
    int? index,
  ) {
    final next = List<MetricDetailEntity>.of(details);
    final safeIndex = index == null
        ? next.length
        : index.clamp(0, next.length).toInt();
    next.insert(safeIndex, detail);

    return next;
  }

  static List<MetricDetailEntity> _insertManyAt(
    List<MetricDetailEntity> details,
    List<MetricDetailEntity> inserted,
    int? index,
  ) {
    final next = List<MetricDetailEntity>.of(details);
    final safeIndex = index == null
        ? next.length
        : index.clamp(0, next.length).toInt();
    next.insertAll(safeIndex, inserted);

    return next;
  }

  static ({List<MetricDetailEntity> details, bool inserted}) _insertUnderParent(
    List<MetricDetailEntity> details,
    String parentId,
    MetricDetailEntity detail,
    int? index,
  ) {
    final next = <MetricDetailEntity>[];
    var inserted = false;

    for (final item in details) {
      if (item.id == parentId) {
        next.add(item.copyWith(items: _insertAt(item.items, detail, index)));
        inserted = true;
        continue;
      }

      final nested = _insertUnderParent(item.items, parentId, detail, index);
      next.add(nested.inserted ? item.copyWith(items: nested.details) : item);
      inserted = inserted || nested.inserted;
    }

    return (details: next, inserted: inserted);
  }

  static ({List<MetricDetailEntity> details, bool inserted})
  _insertManyUnderParent(
    List<MetricDetailEntity> details,
    String parentId,
    List<MetricDetailEntity> insertedDetails,
    int? index,
  ) {
    final next = <MetricDetailEntity>[];
    var inserted = false;

    for (final item in details) {
      if (item.id == parentId) {
        next.add(
          item.copyWith(
            items: _insertManyAt(item.items, insertedDetails, index),
          ),
        );
        inserted = true;
        continue;
      }

      final nested = _insertManyUnderParent(
        item.items,
        parentId,
        insertedDetails,
        index,
      );
      next.add(nested.inserted ? item.copyWith(items: nested.details) : item);
      inserted = inserted || nested.inserted;
    }

    return (details: next, inserted: inserted);
  }

  static ({List<MetricDetailEntity> details, bool changed}) _replaceInList(
    List<MetricDetailEntity> details,
    String detailId,
    MetricDetailEntity replacement,
  ) {
    final next = <MetricDetailEntity>[];
    var changed = false;

    for (final detail in details) {
      if (detail.id == detailId) {
        next.add(replacement);
        changed = true;
        continue;
      }

      final nested = _replaceInList(detail.items, detailId, replacement);
      next.add(
        nested.changed ? detail.copyWith(items: nested.details) : detail,
      );
      changed = changed || nested.changed;
    }

    return (details: next, changed: changed);
  }

  static ({List<MetricDetailEntity> details, bool changed}) _ungroupInList(
    List<MetricDetailEntity> details,
    String parentId,
  ) {
    final next = <MetricDetailEntity>[];
    var changed = false;

    for (final detail in details) {
      if (detail.id == parentId) {
        next.add(detail.copyWith(items: const []));
        next.addAll(detail.items);
        changed = true;
        continue;
      }

      final nested = _ungroupInList(detail.items, parentId);
      next.add(
        nested.changed ? detail.copyWith(items: nested.details) : detail,
      );
      changed = changed || nested.changed;
    }

    return (details: next, changed: changed);
  }
}
