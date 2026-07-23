import 'package:equatable/equatable.dart';

abstract class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object?> get props => [];
}

class JournalRefreshed extends JournalEvent {
  const JournalRefreshed();
}

class JournalEntryAdded extends JournalEvent {
  const JournalEntryAdded(this.content);

  final String content;

  @override
  List<Object?> get props => [content];
}
