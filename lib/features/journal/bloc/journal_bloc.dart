import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/journal_repository.dart';
import 'journal_event.dart';
import 'journal_state.dart';

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  JournalBloc(this._repository) : super(_snapshotFrom(_repository)) {
    on<JournalRefreshed>(_onRefreshed);
    on<JournalTodayEntrySaved>(_onTodayEntrySaved);
  }

  final JournalRepository _repository;

  static JournalState _snapshotFrom(JournalRepository repository) =>
      JournalState(
        entries: repository.getAll(),
        hasEntryToday: repository.hasEntryToday(),
        todayEntry: repository.getTodayEntry(),
      );

  void _onRefreshed(JournalRefreshed event, Emitter<JournalState> emit) {
    emit(_snapshotFrom(_repository));
  }

  Future<void> _onTodayEntrySaved(
    JournalTodayEntrySaved event,
    Emitter<JournalState> emit,
  ) async {
    await _repository.saveTodayEntry(
      question: event.question,
      answer: event.answer,
      extra: event.extra,
    );
    emit(_snapshotFrom(_repository));
  }
}
