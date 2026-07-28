import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:forja/core/constants.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/features/journal/bloc/journal_bloc.dart';
import 'package:forja/features/journal/bloc/journal_event.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveEntry() {
    if (_controller.text.trim().isEmpty) return;
    context.read<JournalBloc>().add(JournalEntryAdded(_controller.text.trim()));
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final journalState = context.watch<JournalBloc>().state;
    final entries = journalState.entries;
    final hasEntryToday = journalState.hasEntryToday;
    final text = Theme.of(context).textTheme;

    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final question =
        ForjaQuestions.list[dayOfYear % ForjaQuestions.list.length];

    return Scaffold(
      appBar: AppBar(title: const Text('Diário')),
      body: Column(
        children: [
          if (!hasEntryToday)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ForjaColors.ember.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ForjaColors.ember.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERGUNTA DO DIA',
                          style: text.labelSmall?.copyWith(
                            color: ForjaColors.ember,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question,
                          style: text.titleMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: ForjaColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    minLines: 4,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Sua resposta...',
                      filled: true,
                      fillColor: ForjaColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saveEntry,
                    child: const Text('Salvar Entrada'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ForjaColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ForjaColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(entry.date),
                        style: text.labelSmall?.copyWith(
                          color: ForjaColors.ember,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(entry.content, style: text.bodyLarge),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
