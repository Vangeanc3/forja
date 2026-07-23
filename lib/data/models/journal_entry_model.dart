import 'package:forja/domain/entities/journal_entry_entity.dart';

class JournalEntryModel extends JournalEntryEntity {
  const JournalEntryModel({required super.content, required super.date});

  factory JournalEntryModel.fromEntity(JournalEntryEntity entity) =>
      JournalEntryModel(content: entity.content, date: entity.date);

  factory JournalEntryModel.fromMap(Map<dynamic, dynamic> map) =>
      JournalEntryModel(
        content: map['content'] as String,
        date: DateTime.parse(map['date'] as String),
      );

  Map<String, dynamic> toMap() => {
    'content': content,
    'date': date.toIso8601String(),
  };
}
