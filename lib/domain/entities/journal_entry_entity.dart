class JournalEntryEntity {
  const JournalEntryEntity({
    required this.date,
    DateTime? updatedAt,
    this.content = '',
    this.question = '',
    this.answer = '',
    this.extra = '',
  }) : updatedAt = updatedAt ?? date;

  final String content;
  final DateTime date;
  final DateTime updatedAt;
  final String question;
  final String answer;
  final String extra;

  bool get hasStructuredContent =>
      question.trim().isNotEmpty ||
      answer.trim().isNotEmpty ||
      extra.trim().isNotEmpty;

  String get displayContent {
    if (!hasStructuredContent) return content;

    final parts = <String>[];
    final trimmedQuestion = question.trim();
    final trimmedAnswer = answer.trim();
    final trimmedExtra = extra.trim();

    if (trimmedAnswer.isNotEmpty) {
      if (trimmedQuestion.isNotEmpty) {
        parts.add('**Pergunta:** $trimmedQuestion\n\n$trimmedAnswer');
      } else {
        parts.add(trimmedAnswer);
      }
    }

    if (trimmedExtra.isNotEmpty) {
      parts.add('**Anotação livre:**\n\n$trimmedExtra');
    }

    return parts.join('\n\n');
  }
}
