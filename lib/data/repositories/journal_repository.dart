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

  Future<void> addEntry(String content) async {
    final entry = JournalEntryModel(content: content, date: DateTime.now());
    await _box.put(_entryId(entry), entry.toMap());
    await _syncEntry(entry);
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
    final today = DateTime.now();
    return _box.values.whereType<Map>().any((e) {
      final date = DateTime.parse(e['date'] as String);
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    });
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

  String _entryId(JournalEntryModel entry) =>
      entry.date.microsecondsSinceEpoch.toString();
}
