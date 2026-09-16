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
  final _extraFocusNode = FocusNode();
  JournalEntryEntity? _previewTodayEntry;
  int _viewIndex = 0; // 0: Escrever hoje, 1: Histórico
  String _selectedMood = '';
  bool _editingToday = true;
  bool _loadedInitialEntry = false;

  final List<Map<String, String>> _moods = [
    {'label': 'Focado', 'icon': '🎯'},
    {'label': 'Produtivo', 'icon': '⚡'},
    {'label': 'Equilibrado', 'icon': '⚖️'},
    {'label': 'Cansado', 'icon': '🔋'},
  ];

  @override
  void dispose() {
    _answerController.dispose();
    _extraController.dispose();
    _extraFocusNode.dispose();
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
      _selectedMood = '';
      _answerController.clear();
      _extraController.clear();
      return;
    }

    _selectedMood = entry.mood;
    _answerController.text = entry.answer;
    _extraController.text = entry.extra.isNotEmpty ? entry.extra : entry.content;
  }

  void _startEditing(JournalEntryEntity? entry) {
    _loadTodayEntry(entry);
    setState(() {
      _editingToday = true;
    });
  }

  void _cancelEditing(JournalEntryEntity? entry) {
    _loadTodayEntry(entry);
    setState(() => _editingToday = entry == null);
  }


  void _saveEntry({
    required String question,
    required JournalEntryEntity? currentEntry,
  }) {
    final answer = _answerController.text.trim();
    final extra = _extraController.text.trim();

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
      question: question,
      answer: answer,
      extra: extra,
      mood: _selectedMood,
    );

    context.read<JournalBloc>().add(
      JournalTodayEntrySaved(
        question: question,
        answer: answer,
        extra: extra,
        mood: _selectedMood,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;
    final horizontalPadding = isSmallMobile ? 12.0 : 20.0;
    final cardInnerPadding = isSmallMobile ? 16.0 : 26.0;

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

    final primaryOrange = const Color(0xFFFF6D00);
    const paperColor = Color(0xFF141414);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Diário de Bordo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // Navegação por abas estilo caderno
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildResponsiveTabButton(
                          0,
                          'Folha de Hoje',
                          Icons.edit_note,
                          primaryOrange,
                          isSmallMobile,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildResponsiveTabButton(
                          1,
                          'Entradas Passadas',
                          Icons.auto_stories,
                          primaryOrange,
                          isSmallMobile,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: _viewIndex == 0
                      ? _buildFolhaDeHoje(
                          paperColor,
                          primaryOrange,
                          question,
                          todayEntry,
                          cardInnerPadding,
                          isSmallMobile,
                        )
                      : _buildHistoryView(
                          ForjaColors.surface,
                          primaryOrange,
                          previousEntries,
                          isSmallMobile,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolhaDeHoje(
    Color paperColor,
    Color primaryOrange,
    String question,
    JournalEntryEntity? todayEntry,
    double innerPadding,
    bool isSmallMobile,
  ) {
    final now = DateTime.now();
    final dayStr = DateFormat('d', 'pt_BR').format(now);
    final monthYearStr = DateFormat('\'de\' MMMM, yyyy', 'pt_BR').format(now);
    final dayOfWeekStr = DateFormat('EEEE', 'pt_BR').format(now);

    final totalWords = (_answerController.text.trim().isEmpty
            ? 0
            : _answerController.text.trim().split(RegExp(r'\s+')).length) +
        (_extraController.text.trim().isEmpty
            ? 0
            : _extraController.text.trim().split(RegExp(r'\s+')).length);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          color: paperColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Não força esticar até o fim da tela
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho da Folha sem overflow
            Padding(
              padding: EdgeInsets.fromLTRB(innerPadding, 18, innerPadding, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        dayStr,
                        style: TextStyle(
                          fontSize: isSmallMobile ? 30 : 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthYearStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isSmallMobile ? 14 : 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              dayOfWeekStr.capitalize(),
                              style: TextStyle(
                                fontSize: isSmallMobile ? 11 : 12,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryOrange.withValues(alpha: 0.1),
                          border: Border.all(color: primaryOrange.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PÁGINA DO DIA',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 9 : 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.bold,
                            color: primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Humor do dia em linha horizontal compacta
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _moods.map((m) {
                        final isSel = _selectedMood == m['label'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text('${m['icon']} ${m['label']}'),
                            selected: isSel,
                            onSelected: (val) =>
                                setState(() => _selectedMood = val ? m['label']! : ''),
                            backgroundColor: Colors.white.withValues(alpha: 0.03),
                            selectedColor: primaryOrange.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              fontSize: isSmallMobile ? 11.5 : 12,
                              color: isSel ? primaryOrange : Colors.white60,
                            ),
                            side: BorderSide(
                              color: isSel ? primaryOrange : Colors.white10,
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

            // Seção 1: Reflexão Diária
            Padding(
              padding: EdgeInsets.fromLTRB(innerPadding, 16, innerPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        color: primaryOrange,
                        size: isSmallMobile ? 15 : 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'REFLEXÃO DIÁRIA',
                        style: TextStyle(
                          color: primaryOrange,
                          fontSize: isSmallMobile ? 10.5 : 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '“$question”',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 14 : 15,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFF0F0F0),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _answerController,
                    maxLines: 4,
                    minLines: 2,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallMobile ? 13.5 : 14,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Escreva sua reflexão sobre essa pergunta...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: isSmallMobile ? 12.5 : 13,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryOrange.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subtítulo sutil de transição para escrita livre
            Padding(
              padding: EdgeInsets.fromLTRB(innerPadding, 20, innerPadding, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: isSmallMobile ? 16 : 18,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Crônica do Dia & Notas Livres',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: isSmallMobile ? 11.5 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.06))),
                ],
              ),
            ),

            // Seção 2: Área Ampla de Escrita
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _extraFocusNode.requestFocus(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: innerPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: isSmallMobile ? 140 : 180,
                  ), // Altura acolhedora sem vácuo
                  child: TextField(
                    controller: _extraController,
                    focusNode: _extraFocusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: const Color(0xFFEEEEEE),
                      fontSize: isSmallMobile ? 14 : 15,
                      height: 1.8,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Como foi o dia? Registre estudos para o concurso da PC, rotina, treinos, pensamentos...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: isSmallMobile ? 13 : 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Rodapé da Folha com Wrap (sem overflow)
            Container(
              padding: EdgeInsets.symmetric(horizontal: innerPadding, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runAlignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 10,
                children: [
                  Text(
                    totalWords == 0 ? 'Página em branco' : '$totalWords palavras',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: isSmallMobile ? 11.5 : 12,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveEntry(question: question, currentEntry: todayEntry),
                    icon: Icon(Icons.bookmark_added_outlined, size: isSmallMobile ? 15 : 16),
                    label: Text(
                      todayEntry != null ? 'Atualizar Diário' : 'Registrar no Diário',
                      style: TextStyle(fontSize: isSmallMobile ? 13 : 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallMobile ? 16 : 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView(
    Color cardBg,
    Color primaryOrange,
    List<JournalEntryEntity> entries,
    bool isSmallMobile,
  ) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma entrada anterior encontrada.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 30),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;
        return _buildTimelineEntry(entry, primaryOrange, isLast, isSmallMobile);
      },
    );
  }

  Widget _buildTimelineEntry(
    JournalEntryEntity entry,
    Color primaryOrange,
    bool isLast,
    bool isSmallMobile,
  ) {
    final dateStr = DateFormat('dd/MM/yyyy').format(entry.date);
    final dayOfWeekStr = DateFormat('EEEE', 'pt_BR').format(entry.date);
    final timeStr = DateFormat('HH:mm').format(entry.updatedAt);
    final moodData = _moods.firstWhere(
      (m) => m['label'] == entry.mood,
      orElse: () => {'label': '', 'icon': ''},
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coluna da Linha do Tempo contínua
          SizedBox(
            width: isSmallMobile ? 20 : 24,
            child: Column(
              children: [
                Container(
                  width: isSmallMobile ? 10 : 12,
                  height: isSmallMobile ? 10 : 12,
                  margin: const EdgeInsets.only(top: 18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryOrange,
                    border: Border.all(color: const Color(0xFF0F0F0F), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: primaryOrange.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : Container(width: 2, color: Colors.white12),
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallMobile ? 8 : 12),

          // Card da Entrada Passada
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: EdgeInsets.all(isSmallMobile ? 14 : 18),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho da data
                  Row(
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallMobile ? 13 : 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '• ${dayOfWeekStr.capitalize()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: isSmallMobile ? 11 : 12,
                          ),
                        ),
                      ),
                      if (moodData['label']!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${moodData['icon']} ${moodData['label']}',
                            style: TextStyle(
                              fontSize: isSmallMobile ? 10 : 11,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: isSmallMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pergunta e Reflexão (estruturado, sem markdown cru)
                  if (entry.question.isNotEmpty && entry.answer.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(color: primaryOrange.withValues(alpha: 0.7), width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '“${entry.question}”',
                            style: TextStyle(
                              color: primaryOrange.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.answer,
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    if (entry.extra.isNotEmpty) const SizedBox(height: 10),
                  ],

                  // Anotação livre (se houver)
                  if (entry.extra.isNotEmpty)
                    Text(
                      entry.extra,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  // Caso seja um registro antigo que usava apenas o campo content
                  if (entry.question.isEmpty && entry.extra.isEmpty && entry.content.isNotEmpty)
                    Text(
                      entry.content,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveTabButton(
    int index,
    String label,
    IconData icon,
    Color primaryOrange,
    bool isSmall,
  ) {
    final isSelected = _viewIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _viewIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: isSmall ? 4 : 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? primaryOrange.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSmall ? 15 : 16,
              color: isSelected ? primaryOrange : Colors.white54,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSmall ? 11.5 : 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? primaryOrange : Colors.white60,
                ),
              ),
            ),
          ],
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

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}



