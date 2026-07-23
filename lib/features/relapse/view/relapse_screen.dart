import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:forja/core/theme.dart';
import 'package:forja/features/home/router/home_router.dart';
import 'package:forja/features/stats/bloc/stats_bloc.dart';
import 'package:forja/features/stats/bloc/stats_event.dart';
import 'package:forja/features/streak/bloc/streak_bloc.dart';
import 'package:forja/features/streak/bloc/streak_event.dart';

class RelapseScreen extends StatelessWidget {
  const RelapseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Recaída')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text('Isso faz parte\ndo processo.', style: text.headlineLarge),
              const SizedBox(height: 16),
              Text(
                'A forja aquece o metal para torná-lo mais forte. '
                'Levante-se e continue.',
                style: text.bodyLarge?.copyWith(height: 1.6),
              ),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: () {
                  // Registra o streak atual nas estatísticas antes de resetar
                  final streakBloc = context.read<StreakBloc>();
                  final statsBloc = context.read<StatsBloc>();
                  final currentDays = streakBloc.state.days;

                  statsBloc.add(StatsRelapseRecorded(currentDays));
                  streakBloc.add(const StreakRelapsed());

                  if (context.mounted) context.go(HomeRouter.initial);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: ForjaColors.error,
                ),
                child: const Text('REINICIAR CONTADOR'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('CANCELAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
