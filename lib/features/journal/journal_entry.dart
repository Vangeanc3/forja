import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  final String content;

  @HiveField(1)
  final DateTime date;

  JournalEntry({
    required this.content,
    required this.date,
  });
}
