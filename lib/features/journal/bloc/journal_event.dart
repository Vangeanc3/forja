import 'package:equatable/equatable.dart';

abstract class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object?> get props => [];
}

class JournalRefreshed extends JournalEvent {
  const JournalRefreshed();
}

class JournalTodayEntrySaved extends JournalEvent {
  const JournalTodayEntrySaved({
    required this.question,
    required this.answer,
    required this.extra,
    this.mood = '',
  });

  final String question;
  final String answer;
  final String extra;
  final String mood;

  @override
  List<Object?> get props => [question, answer, extra, mood];
}
