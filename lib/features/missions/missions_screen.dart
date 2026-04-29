import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/mission.dart';
import '../../data/providers/providers.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = ref.watch(missionsProvider);
    final text = Theme.of(context).textTheme;
    final done = missions.where((m) => m.completed).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Missões')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Hoje', style: text.headlineMedium),
                  const Spacer(),
                  Text('$done / ${missions.length}', style: text.labelLarge),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: missions.isEmpty ? 0 : done / missions.length,
                  backgroundColor: ForjaColors.divider,
                  valueColor:
                      const AlwaysStoppedAnimation(ForjaColors.ember),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: missions.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final mission = missions[i];
                    return _MissionTile(
                      mission: mission,
                      onToggle: () {
                        // Incrementa estatística somente ao concluir (não ao desmarcar)
                        if (!mission.completed) {
                          ref
                              .read(statsProvider.notifier)
                              .incrementMissions();
                        }
                        ref
                            .read(missionsProvider.notifier)
                            .toggle(mission.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission, required this.onToggle});

  final Mission mission;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: mission.completed,
        onChanged: (_) => onToggle(),
        title: Text(
          mission.title,
          style: TextStyle(
            color: mission.completed
                ? ForjaColors.textSecondary
                : ForjaColors.textPrimary,
            decoration:
                mission.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        activeColor: ForjaColors.ember,
        checkColor: ForjaColors.onEmber,
        side: const BorderSide(color: ForjaColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
