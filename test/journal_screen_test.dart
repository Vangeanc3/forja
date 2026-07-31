import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/data/repositories/journal_repository.dart';
import 'package:forja/domain/entities/journal_entry_entity.dart';
import 'package:forja/features/journal/bloc/journal_bloc.dart';
import 'package:forja/features/journal/view/journal_screen.dart';

void main() {
  testWidgets('comeca com pergunta e anotacao livre ativas', (tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => JournalBloc(_MemoryJournalRepository()),
        child: MaterialApp(theme: forjaDarkTheme, home: const JournalScreen()),
      ),
    );

    expect(find.text('Responder pergunta'), findsOneWidget);
    expect(find.text('Anotação livre'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.tap(find.text('Registrar algo além da pergunta.'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('salva hoje e mostra a pagina em modo leitura', (tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => JournalBloc(_MemoryJournalRepository()),
        child: MaterialApp(theme: forjaDarkTheme, home: const JournalScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Mantive o foco.');
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SALVAR PÁGINA'));
    await tester.pumpAndSettle();

    expect(find.text('Página de hoje'), findsOneWidget);
    expect(find.text('SALVO'), findsOneWidget);
    expect(find.text('Mantive o foco.'), findsOneWidget);

    await tester.tap(find.text('EDITAR'));
    await tester.pumpAndSettle();

    expect(find.text('Editando hoje'), findsOneWidget);
    expect(find.text('SALVAR ALTERAÇÕES'), findsOneWidget);
  });
}

class _MemoryJournalRepository extends JournalRepository {
  JournalEntryEntity? _todayEntry;

  @override
  List<JournalEntryEntity> getAll() {
    final entry = _todayEntry;
    return entry == null ? const [] : [entry];
  }

  @override
  JournalEntryEntity? getTodayEntry() => _todayEntry;

  @override
  bool hasEntryToday() => _todayEntry != null;

  @override
  Future<void> saveTodayEntry({
    required String question,
    required String answer,
    required String extra,
  }) async {
    final now = DateTime.now();
    _todayEntry = JournalEntryEntity(
      date: _todayEntry?.date ?? now,
      updatedAt: now,
      question: question,
      answer: answer,
      extra: extra,
    );
  }
}
