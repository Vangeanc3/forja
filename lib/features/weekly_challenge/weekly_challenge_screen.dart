import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/providers/providers.dart';
import 'weekly_challenge_repository.dart';

class WeeklyChallengeScreen extends ConsumerWidget {
  const WeeklyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(weeklyChallengeRepositoryProvider);
    final challenge = repo.getCurrentChallenge();
    final isAccepted = ref.watch(weeklyChallengeProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Desafio Semanal')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔥',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              challenge.title,
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              challenge.description,
              style: text.bodyLarge?.copyWith(color: ForjaColors.textSecondary),
            ),
            const Spacer(),
            if (isAccepted)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Desafio aceito! Mantenha a disciplina.',
                        style: text.bodyMedium?.copyWith(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              )
            else
              FilledButton(
                onPressed: () => ref.read(weeklyChallengeProvider.notifier).accept(true),
                child: const Text('ACEITAR DESAFIO'),
              ),
            const SizedBox(height: 12),
            if (isAccepted)
              OutlinedButton(
                onPressed: () {
                   // No prompt diz "marca como aceito/concluído". 
                   // Vou permitir desmarcar caso o usuário tenha clicado sem querer, 
                   // mas o foco é aceitar.
                   ref.read(weeklyChallengeProvider.notifier).accept(false);
                },
                child: const Text('DESISTIR (NÃO RECOMENDADO)'),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
