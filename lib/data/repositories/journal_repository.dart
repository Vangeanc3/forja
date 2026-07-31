import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:forja/data/models/journal_entry_model.dart';
import 'package:forja/domain/entities/journal_entry_entity.dart';
import '../../core/constants.dart';
import '../services/firebase_sync_service.dart';

class JournalRepository {
  JournalRepository({FirebaseSyncService? firebaseSync})
    : _firebaseSync = firebaseSync;

  final FirebaseSyncService? _firebaseSync;

  Box get _box => Hive.box(ForjaBoxes.journal);

  List<JournalEntryEntity> getAll() {
    final entries = _box.values
        .whereType<Map>()
        .map(JournalEntryModel.fromMap)
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  JournalEntryEntity? getTodayEntry() => _todayEntry();

  Future<void> saveTodayEntry({
    required String question,
    required String answer,
    required String extra,
  }) async {
    final existingEntry = _todayEntry();
    final entry = JournalEntryModel(
      date: existingEntry?.date ?? DateTime.now(),
      updatedAt: DateTime.now(),
      question: question,
      answer: answer,
      extra: extra,
    );

    await _box.put(_entryId(entry), entry.toMap());
    unawaited(_syncEntry(entry));
  }

  Future<void> syncAll() async {
    for (final entry in getAll()) {
      await _syncEntry(JournalEntryModel.fromEntity(entry));
    }
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> mergeRemote(List<FirebaseSyncDocument> documents) async {
    for (final document in documents) {
      final entry = JournalEntryModel.fromMap(document.data);
      if (_hasEntry(entry)) continue;
      await _box.put(document.id, entry.toMap());
    }

    await syncAll();
  }

  bool hasEntryToday() {
    return _todayEntry() != null;
  }

  Future<void> _syncEntry(JournalEntryModel entry) {
    return _firebaseSync?.setDocument(
          'journalEntries',
          entry.date.microsecondsSinceEpoch.toString(),
          entry.toMap(),
        ) ??
        Future.value();
  }

  bool _hasEntry(JournalEntryModel entry) {
    return _box.values.whereType<Map>().any((stored) {
      final storedEntry = JournalEntryModel.fromMap(stored);
      return _entryId(storedEntry) == _entryId(entry) &&
          storedEntry.content == entry.content;
    });
  }

  JournalEntryModel? _todayEntry() {
    final today = DateTime.now();
    final todayEntries = _box.values
        .whereType<Map>()
        .map(JournalEntryModel.fromMap)
        .where((entry) => _isSameDay(entry.date, today))
        .toList();

    if (todayEntries.isEmpty) return null;
    todayEntries.sort((a, b) => b.date.compareTo(a.date));
    return todayEntries.first;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _entryId(JournalEntryModel entry) =>
      entry.date.microsecondsSinceEpoch.toString();
}
