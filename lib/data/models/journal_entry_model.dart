import 'package:forja/domain/entities/journal_entry_entity.dart';

class JournalEntryModel extends JournalEntryEntity {
  JournalEntryModel({
    required super.date,
    super.updatedAt,
    super.question = '',
    super.answer = '',
    super.extra = '',
    String? content,
  }) : super(content: content ?? _buildContent(question, answer, extra));

  factory JournalEntryModel.fromEntity(JournalEntryEntity entity) =>
      JournalEntryModel(
        date: entity.date,
        updatedAt: entity.updatedAt,
        content: entity.content.trim().isEmpty && entity.hasStructuredContent
            ? null
            : entity.content,
        question: entity.question,
        answer: entity.answer,
        extra: entity.extra,
      );

  factory JournalEntryModel.fromMap(Map<dynamic, dynamic> map) =>
      JournalEntryModel(
        date: DateTime.parse(map['date'] as String),
        updatedAt: _dateFrom(map['updatedAt']),
        content: map['content'] as String? ?? '',
        question: map['question'] as String? ?? '',
        answer: map['answer'] as String? ?? '',
        extra: map['extra'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
    'content': content,
    'date': date.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'question': question,
    'answer': answer,
    'extra': extra,
  };
}

DateTime? _dateFrom(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _buildContent(String question, String answer, String extra) {
  final parts = <String>[];
  final trimmedQuestion = question.trim();
  final trimmedAnswer = answer.trim();
  final trimmedExtra = extra.trim();

  if (trimmedAnswer.isNotEmpty) {
    if (trimmedQuestion.isNotEmpty) {
      parts.add('Pergunta: $trimmedQuestion\n\n$trimmedAnswer');
    } else {
      parts.add(trimmedAnswer);
    }
  }

  if (trimmedExtra.isNotEmpty) {
    parts.add(trimmedExtra);
  }

  return parts.join('\n\n');
}
