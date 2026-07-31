import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:forja/core/constants.dart';
import 'package:forja/data/models/journal_entry_model.dart';
import 'package:forja/data/repositories/journal_repository.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() {
    hiveDirectory = Directory.systemTemp.createTempSync('forja_journal_test_');
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    if (!Hive.isBoxOpen(ForjaBoxes.journal)) {
      await Hive.openBox(ForjaBoxes.journal);
    }
    await Hive.box(ForjaBoxes.journal).clear();
  });

  test('atualiza a entrada de hoje sem criar duplicata', () async {
    final repository = JournalRepository();

    await repository.saveTodayEntry(
      question: 'O que te fez forte hoje?',
      answer: 'Treinei cedo.',
      extra: '',
    );

    final firstEntry = repository.getTodayEntry();

    await repository.saveTodayEntry(
      question: 'O que te fez forte hoje?',
      answer: 'Treinei cedo e estudei.',
      extra: 'Amanhã revisar Português.',
    );

    final entries = repository.getAll();
    final todayEntry = repository.getTodayEntry();

    expect(entries, hasLength(1));
    expect(todayEntry?.date, firstEntry?.date);
    expect(todayEntry?.answer, 'Treinei cedo e estudei.');
    expect(todayEntry?.extra, 'Amanhã revisar Português.');
  });

  test('mantem compatibilidade com entradas antigas somente com content', () {
    final entry = JournalEntryModel.fromMap({
      'date': DateTime(2026, 7, 30).toIso8601String(),
      'content': 'Texto antigo do diário',
    });

    expect(entry.hasStructuredContent, isFalse);
    expect(entry.displayContent, 'Texto antigo do diário');
  });
}
