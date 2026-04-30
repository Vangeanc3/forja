import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import 'journal_entry.dart';

class JournalRepository {
  Box<JournalEntry> get _box => Hive.box<JournalEntry>(ForjaBoxes.journal);

  List<JournalEntry> getAll() {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<void> addEntry(String content) async {
    final entry = JournalEntry(
      content: content,
      date: DateTime.now(),
    );
    await _box.add(entry);
  }

  // Permite apenas uma entrada por dia (simplificado para o prompt)
  bool hasEntryToday() {
    final today = DateTime.now();
    return _box.values.any((e) =>
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day);
  }
}
