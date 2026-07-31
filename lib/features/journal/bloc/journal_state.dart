import 'package:equatable/equatable.dart';

import 'package:forja/domain/entities/journal_entry_entity.dart';

class JournalState extends Equatable {
  const JournalState({
    required this.entries,
    required this.hasEntryToday,
    this.todayEntry,
  });

  final List<JournalEntryEntity> entries;
  final bool hasEntryToday;
  final JournalEntryEntity? todayEntry;

  @override
  List<Object?> get props => [entries, hasEntryToday, todayEntry];
}
