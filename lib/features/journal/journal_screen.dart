import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/providers/providers.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveEntry() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(journalProvider.notifier).addEntry(_controller.text.trim());
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalProvider);
    final repo = ref.read(journalRepositoryProvider);
    final hasEntryToday = repo.hasEntryToday();
    final text = Theme.of(context).textTheme;

    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final question = ForjaQuestions.list[dayOfYear % ForjaQuestions.list.length];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário'),
      ),
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
                      border: Border.all(color: ForjaColors.ember.withValues(alpha: 0.3)),
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
                    maxLines: 4,
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
              separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                        style: text.labelSmall?.copyWith(color: ForjaColors.ember),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.content,
                        style: text.bodyLarge,
                      ),
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
