import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:forja/core/constants.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/domain/entities/journal_entry_entity.dart';
import 'package:forja/features/journal/bloc/journal_bloc.dart';
import 'package:forja/features/journal/bloc/journal_event.dart';
import 'package:forja/shared/widgets/formatted_text.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _answerController = TextEditingController();
  final _extraController = TextEditingController();
  JournalEntryEntity? _previewTodayEntry;
  bool _useQuestion = true;
  bool _useExtra = true;
  bool _editingToday = true;
  bool _loadedInitialEntry = false;

  @override
  void dispose() {
    _answerController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedInitialEntry) return;

    final todayEntry = context.read<JournalBloc>().state.todayEntry;
    _loadTodayEntry(todayEntry);
    _editingToday = todayEntry == null;
    _loadedInitialEntry = true;
  }

  void _loadTodayEntry(JournalEntryEntity? entry) {
    if (entry == null) {
      _useQuestion = true;
      _useExtra = true;
      _answerController.clear();
      _extraController.clear();
      return;
    }

    final hasAnswer =
        entry.answer.trim().isNotEmpty || entry.question.trim().isNotEmpty;
    final hasExtra = entry.extra.trim().isNotEmpty;
    final isLegacyEntry =
        !entry.hasStructuredContent && entry.content.trim().isNotEmpty;

    _useQuestion = hasAnswer;
    _useExtra = hasExtra || isLegacyEntry;
    if (!_useQuestion && !_useExtra) {
      _useQuestion = true;
    }

    _answerController.text = entry.answer;
    _extraController.text = hasExtra ? entry.extra : entry.content;
  }

  void _startEditing(JournalEntryEntity? entry, {bool forceExtra = false}) {
    _loadTodayEntry(entry);
    setState(() {
      _editingToday = true;
      if (forceExtra) {
        _useExtra = true;
      }
    });
  }

  void _cancelEditing(JournalEntryEntity? entry) {
    _loadTodayEntry(entry);
    setState(() => _editingToday = entry == null);
  }

  void _toggleQuestion(bool selected) {
    setState(() {
      _useQuestion = selected;
      if (!_useQuestion && !_useExtra) {
        _useExtra = true;
      }
    });
  }

  void _toggleExtra(bool selected) {
    setState(() {
      _useExtra = selected;
      if (!_useQuestion && !_useExtra) {
        _useQuestion = true;
      }
    });
  }

  void _saveEntry({
    required String question,
    required JournalEntryEntity? currentEntry,
  }) {
    final answer = _useQuestion ? _answerController.text.trim() : '';
    final extra = _useExtra ? _extraController.text.trim() : '';

    if (answer.isEmpty && extra.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreva algo para salvar no diário.')),
      );
      return;
    }

    final now = DateTime.now();
    final previewEntry = JournalEntryEntity(
      date: currentEntry?.date ?? now,
      updatedAt: now,
      question: _useQuestion ? question : '',
      answer: answer,
      extra: extra,
    );

    context.read<JournalBloc>().add(
      JournalTodayEntrySaved(
        question: _useQuestion ? question : '',
        answer: answer,
        extra: extra,
      ),
    );

    setState(() {
      _previewTodayEntry = previewEntry;
      _editingToday = false;
    });
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            currentEntry != null
                ? 'Entrada de hoje atualizada.'
                : 'Entrada de hoje salva.',
          ),
          action: SnackBarAction(
            label: 'Editar',
            onPressed: () => _startEditing(
              _previewTodayEntry ??
                  context.read<JournalBloc>().state.todayEntry,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final journalState = context.watch<JournalBloc>().state;
    final todayEntry = _previewTodayEntry ?? journalState.todayEntry;
    final previousEntries = journalState.entries
        .where((entry) => !_isToday(entry.date))
        .toList();

    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final question =
        ForjaQuestions.list[dayOfYear % ForjaQuestions.list.length];

    return Scaffold(
      appBar: AppBar(title: const Text('Diário')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: previousEntries.length + 2,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              if (!_editingToday && todayEntry != null) {
                return _TodayJournalPage(
                  entry: todayEntry,
                  onEdit: () => _startEditing(todayEntry),
                  onAddNote: () => _startEditing(todayEntry, forceExtra: true),
                );
              }

              return _TodayJournalEditor(
                question: question,
                hasEntryToday: todayEntry != null,
                useQuestion: _useQuestion,
                useExtra: _useExtra,
                answerController: _answerController,
                extraController: _extraController,
                onToggleQuestion: _toggleQuestion,
                onToggleExtra: _toggleExtra,
                onCancel: todayEntry != null
                    ? () => _cancelEditing(todayEntry)
                    : null,
                onSave: () =>
                    _saveEntry(question: question, currentEntry: todayEntry),
              );
            }

            if (index == 1) {
              return _JournalHistoryHeader(
                hasEntries: previousEntries.isNotEmpty,
                count: previousEntries.length,
              );
            }

            final entry = previousEntries[index - 2];
            return _JournalEntryCard(entry: entry);
          },
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _TodayJournalPage extends StatelessWidget {
  const _TodayJournalPage({
    required this.entry,
    required this.onEdit,
    required this.onAddNote,
  });

  final JournalEntryEntity entry;
  final VoidCallback onEdit;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final updatedAt = DateFormat('HH:mm').format(entry.updatedAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ForjaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ForjaColors.ember.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _JournalIcon(icon: Icons.menu_book_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Página de hoje',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Atualizada às $updatedAt',
                      style: text.bodySmall?.copyWith(
                        color: ForjaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _SavedPill(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ForjaColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ForjaColors.divider),
            ),
            child: FormattedText(
              data: entry.displayContent,
              style: text.bodyLarge?.copyWith(
                color: ForjaColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('EDITAR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddNote,
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('ANOTAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayJournalEditor extends StatelessWidget {
  const _TodayJournalEditor({
    required this.question,
    required this.hasEntryToday,
    required this.useQuestion,
    required this.useExtra,
    required this.answerController,
    required this.extraController,
    required this.onToggleQuestion,
    required this.onToggleExtra,
    required this.onSave,
    this.onCancel,
  });

  final String question;
  final bool hasEntryToday;
  final bool useQuestion;
  final bool useExtra;
  final TextEditingController answerController;
  final TextEditingController extraController;
  final ValueChanged<bool> onToggleQuestion;
  final ValueChanged<bool> onToggleExtra;
  final VoidCallback onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

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
          Row(
            children: [
              const _JournalIcon(icon: Icons.edit_note_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasEntryToday ? 'Editando hoje' : 'Escrever hoje',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      hasEntryToday
                          ? 'Salve para voltar à página escrita.'
                          : 'Mantenha ativas as partes que quer usar.',
                      style: text.bodySmall?.copyWith(
                        color: ForjaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _JournalSectionToggle(
            icon: Icons.help_outline_rounded,
            title: 'Responder pergunta',
            subtitle: 'Usar a pergunta do dia como ponto de partida.',
            selected: useQuestion,
            onChanged: onToggleQuestion,
          ),
          const SizedBox(height: 8),
          _JournalSectionToggle(
            icon: Icons.add_comment_outlined,
            title: 'Anotação livre',
            subtitle: 'Registrar algo além da pergunta.',
            selected: useExtra,
            onChanged: onToggleExtra,
          ),
          if (useQuestion) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 12),
            FormattedTextField(
              controller: answerController,
              labelText: 'Resposta',
              hintText: 'Escreva sua resposta...',
              minLines: 4,
              filled: true,
              fillColor: ForjaColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ],
          if (useExtra) ...[
            const SizedBox(height: 12),
            FormattedTextField(
              controller: extraController,
              labelText: 'Anotação livre',
              hintText: 'Acrescente pensamentos, fatos ou aprendizados...',
              minLines: 4,
              filled: true,
              fillColor: ForjaColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
            label: Text(hasEntryToday ? 'SALVAR ALTERAÇÕES' : 'SALVAR PÁGINA'),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
              label: const Text('CANCELAR E VOLTAR'),
            ),
          ],
        ],
      ),
    );
  }
}

class _JournalSectionToggle extends StatelessWidget {
  const _JournalSectionToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final borderColor = selected
        ? ForjaColors.ember.withValues(alpha: 0.55)
        : ForjaColors.divider;
    final backgroundColor = selected
        ? ForjaColors.ember.withValues(alpha: 0.08)
        : ForjaColors.background;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? ForjaColors.ember : ForjaColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.bodyLarge?.copyWith(
                        color: ForjaColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(
                        color: ForjaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                onChanged: (value) => onChanged(value ?? false),
                activeColor: ForjaColors.ember,
                side: const BorderSide(color: ForjaColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalHistoryHeader extends StatelessWidget {
  const _JournalHistoryHeader({required this.hasEntries, required this.count});

  final bool hasEntries;
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (!hasEntries) {
      return Text(
        'Nenhuma entrada anterior ainda.',
        style: text.bodyMedium?.copyWith(color: ForjaColors.textSecondary),
        textAlign: TextAlign.center,
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            'HISTÓRICO',
            style: text.labelSmall?.copyWith(
              color: ForjaColors.ember,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Text(
          '$count ${count == 1 ? 'entrada' : 'entradas'}',
          style: text.bodySmall?.copyWith(color: ForjaColors.textSecondary),
        ),
      ],
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({required this.entry});

  final JournalEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('dd/MM/yyyy').format(entry.date),
                  style: text.labelSmall?.copyWith(color: ForjaColors.ember),
                ),
              ),
              Text(
                DateFormat('HH:mm').format(entry.updatedAt),
                style: text.bodySmall?.copyWith(
                  color: ForjaColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FormattedText(
            data: entry.displayContent,
            style: text.bodyLarge?.copyWith(
              color: ForjaColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalIcon extends StatelessWidget {
  const _JournalIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: ForjaColors.ember.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ForjaColors.ember.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: ForjaColors.ember),
    );
  }
}

class _SavedPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: Colors.green, size: 14),
          SizedBox(width: 3),
          Text(
            'SALVO',
            style: TextStyle(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
