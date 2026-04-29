import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/providers/providers.dart';
import '../../features/achievements/achievements_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(streakProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ForjaStrings.appName,
          style: text.titleLarge?.copyWith(color: ForjaColors.ember),
        ),
        actions: [
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
                      'Olá, ${settings.userName}',
                      style: text.bodyMedium,
                    ),
                  ),
                _StreakRing(days: days),
                const SizedBox(height: 8),
                Text(
                  days == 1
                      ? '1 dia de disciplina'
                      : '$days dias de disciplina',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 32),
                SwordWidget(days: days),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: OutlinedButton(
                    onPressed: () => context.push(ForjaRoutes.relapse),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ForjaColors.error,
                      side: const BorderSide(color: ForjaColors.error),
                    ),
                    child: const Text('RECAÍDA'),
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
