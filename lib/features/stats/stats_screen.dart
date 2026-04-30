import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/providers/providers.dart';
import '../achievements/achievement_model.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStreak = ref.watch(streakProvider);
    final stats = ref.watch(statsProvider);

    final bestStreak = math.max(stats.bestStreak, currentStreak);
    final totalDays = stats.totalCleanDays + currentStreak;

    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Streak atual + melhor streak (cards grandes lado a lado)
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _LargeStatCard(
                    label: 'Streak Atual',
                    value: '$currentStreak',
                    unit: 'dias',
                    highlighted: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LargeStatCard(
                    label: 'Melhor Streak',
                    value: '$bestStreak',
                    unit: 'dias',
                    highlighted: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Grid 2×2
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _StatCard(
                label: 'Dias Limpos',
                value: '$totalDays',
                icon: Icons.calendar_today_outlined,
              ),
              _StatCard(
                label: 'Recaídas',
                value: '${stats.totalRelapses}',
                icon: Icons.refresh_rounded,
              ),
              _StatCard(
                label: 'Missões',
                value: '${stats.totalMissionsDone}',
                icon: Icons.check_circle_outline,
              ),
              _StatCard(
                label: 'Membro desde',
                value: stats.memberSince != null
                    ? _fmtDate(stats.memberSince!)
                    : '—',
                icon: Icons.person_outline_rounded,
                smallValue: stats.memberSince != null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _NextMilestoneCard(currentStreak: currentStreak),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(ForjaRoutes.relapseHistory),
            icon: const Icon(Icons.history_rounded),
            label: const Text('HISTÓRICO DE RECAÍDAS'),
            style: FilledButton.styleFrom(
              backgroundColor: ForjaColors.surface,
              foregroundColor: ForjaColors.textPrimary,
              side: const BorderSide(color: ForjaColors.divider),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.push(ForjaRoutes.weeklyReport),
            icon: const Icon(Icons.assignment_rounded),
            label: const Text('RELATÓRIOS SEMANAIS'),
            style: FilledButton.styleFrom(
              backgroundColor: ForjaColors.surface,
              foregroundColor: ForjaColors.textPrimary,
              side: const BorderSide(color: ForjaColors.divider),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const m = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// ── Cards grandes (streak atual e recorde) ───────────────────────────────────

class _LargeStatCard extends StatelessWidget {
  const _LargeStatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.highlighted,
  });

  final String label;
  final String value;
  final String unit;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: ForjaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? ForjaColors.ember : ForjaColors.divider,
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: ForjaColors.ember.withValues(alpha: 0.12),
                  blurRadius: 20,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.bodyMedium?.copyWith(fontSize: 11, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: text.displayMedium?.copyWith(
              color: highlighted ? ForjaColors.ember : ForjaColors.textPrimary,
              fontSize: 48,
              height: 1,
            ),
          ),
          Text(unit, style: text.bodyMedium),
        ],
      ),
    );
  }
}

// ── Cards pequenos (grid 2×2) ─────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.smallValue = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool smallValue;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ForjaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ForjaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 18, color: ForjaColors.textSecondary),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: smallValue
                    ? text.titleLarge?.copyWith(
                        color: ForjaColors.textPrimary, fontSize: 15)
                    : text.headlineMedium?.copyWith(
                        color: ForjaColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: text.bodyMedium?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Card de próximo marco ─────────────────────────────────────────────────────

class _NextMilestoneCard extends StatelessWidget {
  const _NextMilestoneCard({required this.currentStreak});

  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    int prevDays = 0;
    Achievement? next;
    for (final a in kAchievements) {
      if (a.daysRequired > currentStreak) {
        next = a;
        break;
      }
      prevDays = a.daysRequired;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ForjaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ForjaColors.divider),
      ),
      child: next == null
          ? _AllDone(text: text)
          : _MilestoneProgress(
              text: text,
              next: next,
              prevDays: prevDays,
              currentStreak: currentStreak,
            ),
    );
  }
}

class _AllDone extends StatelessWidget {
  const _AllDone({required this.text});
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('🏆', style: TextStyle(fontSize: 32)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Todos os marcos atingidos!',
                  style: text.titleLarge?.copyWith(color: ForjaColors.ember)),
              const SizedBox(height: 4),
              Text('90 dias. Você virou aço.', style: text.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _MilestoneProgress extends StatelessWidget {
  const _MilestoneProgress({
    required this.text,
    required this.next,
    required this.prevDays,
    required this.currentStreak,
  });

  final TextTheme text;
  final Achievement next;
  final int prevDays;
  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final daysLeft = next.daysRequired - currentStreak;
    final range = next.daysRequired - prevDays;
    final progress = ((currentStreak - prevDays) / range).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximo marco',
          style: text.bodyMedium?.copyWith(
            letterSpacing: 0.5,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(next.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(next.title, style: text.titleLarge),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ForjaColors.ember.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                daysLeft == 1 ? 'Falta 1 dia' : 'Faltam $daysLeft dias',
                style: const TextStyle(
                  color: ForjaColors.ember,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: ForjaColors.divider,
            valueColor: const AlwaysStoppedAnimation(ForjaColors.ember),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$prevDays dias', style: text.bodyMedium?.copyWith(fontSize: 10)),
            Text('${next.daysRequired} dias', style: text.bodyMedium?.copyWith(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
