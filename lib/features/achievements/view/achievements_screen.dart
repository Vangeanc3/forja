import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forja/domain/entities/achievement_entity.dart';

import 'package:forja/core/theme.dart';
import 'package:forja/features/achievements/bloc/achievements_bloc.dart';

// ── Tela principal ────────────────────────────────────────────────────────────

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = context.watch<AchievementsBloc>().state.achievements;
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Conquistas')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$unlockedCount',
                  style: text.headlineLarge?.copyWith(color: ForjaColors.ember),
                ),
                Text(' de ${achievements.length}', style: text.headlineMedium),
                const Spacer(),
                Text('desbloqueadas', style: text.bodyMedium),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: achievements.isEmpty
                    ? 0
                    : unlockedCount / achievements.length,
                backgroundColor: ForjaColors.divider,
                valueColor: const AlwaysStoppedAnimation(ForjaColors.ember),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, i) =>
                  _AchievementCard(achievement: achievements[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card de conquista ─────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final AchievementEntity achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    final text = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? ForjaColors.surface : ForjaColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? ForjaColors.ember : ForjaColors.divider,
          width: unlocked ? 1.5 : 1,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: ForjaColors.ember.withValues(alpha: 0.12),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: unlocked ? 1.0 : 0.22,
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
              if (!unlocked)
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: ForjaColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            style: text.titleLarge?.copyWith(
              color: unlocked
                  ? ForjaColors.textPrimary
                  : ForjaColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: text.bodyMedium?.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: unlocked
                  ? ForjaColors.ember.withValues(alpha: 0.15)
                  : ForjaColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${achievement.daysRequired} dias',
              style: TextStyle(
                color: unlocked ? ForjaColors.ember : ForjaColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dialog de conquista desbloqueada ─────────────────────────────────────────

class AchievementUnlockDialog extends StatefulWidget {
  const AchievementUnlockDialog({super.key, required this.achievement});

  final AchievementEntity achievement;

  @override
  State<AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: ForjaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: ForjaColors.ember, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CONQUISTA DESBLOQUEADA',
                style: TextStyle(
                  color: ForjaColors.ember,
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ScaleTransition(
                scale: _scale,
                child: Text(
                  widget.achievement.icon,
                  style: const TextStyle(fontSize: 72),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.achievement.title,
                style: text.headlineMedium?.copyWith(color: ForjaColors.ember),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.achievement.description,
                style: text.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CONTINUAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
