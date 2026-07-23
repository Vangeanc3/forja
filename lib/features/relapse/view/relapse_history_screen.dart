import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/domain/entities/stats_entity.dart';
import 'package:forja/features/stats/bloc/stats_bloc.dart';

class RelapseHistoryScreen extends StatelessWidget {
  const RelapseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsBloc>().state.model;
    final relapses = stats.relapses.reversed.toList();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Recaídas')),
      body: relapses.isEmpty
          ? Center(
              child: Text(
                'Nenhuma recaída registrada.\nContinue firme!',
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
            )
          : Column(
              children: [
                _RiskPatternHeader(relapses: relapses),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: relapses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = relapses[index];
                      return _RelapseCard(entry: entry);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _RiskPatternHeader extends StatelessWidget {
  const _RiskPatternHeader({required this.relapses});
  final List<RelapseEntryEntity> relapses;

  @override
  Widget build(BuildContext context) {
    if (relapses.isEmpty) return const SizedBox.shrink();

    final counts = <int, int>{};
    for (final r in relapses) {
      final day = r.dateTime.weekday;
      counts[day] = (counts[day] ?? 0) + 1;
    }

    final mostFrequentDay = counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final dayNames = [
      '',
      'segundas-feiras',
      'terças-feiras',
      'quartas-feiras',
      'quintas-feiras',
      'sextas-feiras',
      'sábados',
      'domingos',
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ForjaColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ForjaColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: ForjaColors.error),
          const SizedBox(height: 8),
          Text(
            'Padrão de Risco',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ForjaColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Você recai mais às ${dayNames[mostFrequentDay]}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: ForjaColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _RelapseCard extends StatelessWidget {
  const _RelapseCard({required this.entry});
  final RelapseEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dateStr =
        '${entry.dateTime.day}/${entry.dateTime.month}/${entry.dateTime.year}';
    final timeStr =
        '${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ForjaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ForjaColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ForjaColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: ForjaColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dateStr às $timeStr',
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Streak anterior: ${entry.streakDuration} dias',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
