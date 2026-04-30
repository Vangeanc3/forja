import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/providers/providers.dart';
import '../../features/achievements/achievement_model.dart';
import '../../features/achievements/achievements_screen.dart';
import '../../features/weekly_challenge/weekly_challenge_repository.dart';
import '../../shared/widgets/sword_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Verifica conquistas após o primeiro frame para não bloquear a renderização
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAchievements());
  }

  Future<void> _checkAchievements() async {
    if (!mounted) return;
    final days = ref.read(streakProvider);
    final newlyUnlocked =
        await ref.read(achievementsProvider.notifier).checkAndUnlock(days);

    if (newlyUnlocked.isNotEmpty && mounted) {
      // Exibe a conquista de maior tier desbloqueada
      final best = newlyUnlocked
          .reduce((a, b) => a.daysRequired > b.daysRequired ? a : b);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AchievementUnlockDialog(achievement: best),
      );
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Bom dia';
    if (hour >= 12 && hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  void _checkAndGenerateWeeklyReport(WidgetRef ref) {
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return;

    final reportRepo = ref.read(weeklyReportRepositoryProvider);
    if (reportRepo.hasReportForThisWeek()) return;

    final streak = ref.read(streakProvider);
    final isMonk = ref.read(monkModeProvider);
    final challengeDone = ref.read(weeklyChallengeProvider);
    final journalEntries = ref.read(journalProvider);
    final stats = ref.read(statsProvider);

    final report = reportRepo.generateCurrentReport(
      cleanDaysThisWeek: streak >= 7 ? 7 : streak,
      missionsDoneThisWeek: stats.totalMissionsDone,
      challengeCompleted: challengeDone,
      monkModeActive: isMonk,
      journalEntries: journalEntries.map((e) => e.content).toList(),
    );

    Future.microtask(() => ref.read(weeklyReportProvider.notifier).saveReport(report));
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(streakProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final isMonkMode = ref.watch(monkModeProvider);
    final challengeAccepted = ref.watch(weeklyChallengeProvider);
    final challenge = ref.watch(weeklyChallengeRepositoryProvider).getCurrentChallenge();
    final text = Theme.of(context).textTheme;

    // Lógica para gerar relatório se for domingo e ainda não existir
    _checkAndGenerateWeeklyReport(ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ForjaStrings.appName,
          style: text.titleLarge?.copyWith(color: ForjaColors.ember),
        ),
        actions: [
          if (isMonkMode)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('MONGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: ForjaColors.ember,
                labelStyle: TextStyle(color: ForjaColors.onEmber),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Perfil',
            onPressed: () => context.push(ForjaRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.security_rounded),
            tooltip: 'Modo Monge',
            onPressed: () => context.push(ForjaRoutes.monkMode),
          ),
          IconButton(
            icon: const Icon(Icons.book_rounded),
            tooltip: 'Diário',
            onPressed: () => context.push(ForjaRoutes.journal),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Estatísticas',
            onPressed: () => context.push(ForjaRoutes.stats),
          ),
          IconButton(
            icon: const Icon(Icons.military_tech_rounded),
            tooltip: 'Conquistas',
            onPressed: () => context.push(ForjaRoutes.achievements),
          ),
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: 'Missões',
            onPressed: () => context.push(ForjaRoutes.missions),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                if (settings.userName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_greeting()}, ${settings.userName}',
                      style: text.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                _DailyQuote(),
                _StreakRing(days: days),
                const SizedBox(height: 8),
                Text(
                  days == 1
                      ? '1 dia de disciplina'
                      : '$days dias de disciplina',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 16),
                _NextAchievementProgress(currentDays: days),
                const SizedBox(height: 32),
                SwordWidget(days: days),
                if (settings.userReason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '"${settings.userReason}"',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: ForjaColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                _WeeklyChallengeCard(
                  challenge: challenge,
                  isAccepted: challengeAccepted,
                  onTap: () => context.push(ForjaRoutes.weeklyChallenge),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      FilledButton(
                        onPressed: () => context.push(ForjaRoutes.urgency),
                        style: FilledButton.styleFrom(
                          backgroundColor: ForjaColors.ember,
                          foregroundColor: ForjaColors.onEmber,
                        ),
                        child: const Text('ESTOU COM VONTADE'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => context.push(ForjaRoutes.relapse),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ForjaColors.error,
                          side: const BorderSide(color: ForjaColors.error),
                        ),
                        child: const Text('RECAÍDA'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyQuote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final quote = ForjaQuotes.list[dayOfYear % ForjaQuotes.list.length];
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      child: Text(
        '"$quote"',
        textAlign: TextAlign.center,
        style: text.bodyMedium?.copyWith(
          color: ForjaColors.textPrimary.withValues(alpha: 0.9),
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _WeeklyChallengeCard extends StatelessWidget {
  const _WeeklyChallengeCard({
    required this.challenge,
    required this.isAccepted,
    required this.onTap,
  });

  final WeeklyChallenge challenge;
  final bool isAccepted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ForjaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAccepted ? ForjaColors.ember : ForjaColors.divider,
              width: isAccepted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DESAFIO SEMANAL',
                    style: text.labelLarge?.copyWith(
                      color: isAccepted ? ForjaColors.ember : ForjaColors.textSecondary,
                    ),
                  ),
                  if (isAccepted)
                    const Icon(Icons.verified_rounded, color: ForjaColors.ember, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                challenge.title,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isAccepted ? 'Em progresso...' : 'Toque para ver detalhes e aceitar',
                style: text.bodySmall?.copyWith(color: ForjaColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextAchievementProgress extends StatelessWidget {
  const _NextAchievementProgress({required this.currentDays});
  final int currentDays;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    
    // Encontrar a próxima conquista
    Achievement? next;
    for (final a in kAchievements) {
      if (currentDays < a.daysRequired) {
        next = a;
        break;
      }
    }

    if (next == null) return const SizedBox.shrink();

    final remaining = next.daysRequired - currentDays;
    // Progresso relativo à conquista anterior
    int previousGoal = 0;
    for (final a in kAchievements) {
      if (a.daysRequired < next.daysRequired) {
        previousGoal = a.daysRequired;
      }
    }

    final totalToNext = next.daysRequired - previousGoal;
    final currentProgress = currentDays - previousGoal;
    final progressPercent = (currentProgress / totalToNext).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Text(
            '$remaining dias para ${next.title} ${next.icon}',
            style: text.bodySmall?.copyWith(color: ForjaColors.ember, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 6,
              backgroundColor: ForjaColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(ForjaColors.ember),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakRing extends StatelessWidget {
  const _StreakRing({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ForjaColors.ember, width: 3),
        color: ForjaColors.surface,
        boxShadow: [
          BoxShadow(
            color: ForjaColors.ember.withValues(alpha: 0.16),
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$days',
            style: text.displayLarge?.copyWith(
              color: ForjaColors.ember,
              fontSize: 64,
            ),
          ),
          Text('dias', style: text.bodyMedium),
        ],
      ),
    );
  }
}
