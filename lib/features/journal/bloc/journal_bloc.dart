import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/journal_repository.dart';
import 'journal_event.dart';
import 'journal_state.dart';

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  JournalBloc(this._repository) : super(_snapshotFrom(_repository)) {
    on<JournalRefreshed>(_onRefreshed);
    on<JournalEntryAdded>(_onEntryAdded);
  }

  final JournalRepository _repository;

  static JournalState _snapshotFrom(JournalRepository repository) =>
      JournalState(
        entries: repository.getAll(),
        hasEntryToday: repository.hasEntryToday(),
      );

  void _onRefreshed(JournalRefreshed event, Emitter<JournalState> emit) {
    emit(_snapshotFrom(_repository));
  }

  Future<void> _onEntryAdded(
    JournalEntryAdded event,
    Emitter<JournalState> emit,
  ) async {
    await _repository.addEntry(event.content);
    emit(_snapshotFrom(_repository));
  }
}
