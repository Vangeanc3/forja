import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/providers/providers.dart';

class RelapseScreen extends ConsumerWidget {
  const RelapseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                onPressed: () async {
                  // Registra o streak atual nas estatísticas antes de resetar
                  final currentDays = ref.read(streakProvider);
                  await ref
                      .read(statsProvider.notifier)
                      .recordRelapse(currentDays);
                  await ref.read(streakProvider.notifier).relapse();
                  if (context.mounted) context.go(ForjaRoutes.home);
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
