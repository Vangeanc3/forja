import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forja/core/theme.dart';
import 'package:forja/domain/entities/mission_entity.dart';
import 'package:forja/features/missions/bloc/missions_bloc.dart';
import 'package:forja/features/missions/bloc/missions_event.dart';
import 'package:forja/features/settings/bloc/settings_bloc.dart';
import 'package:forja/features/settings/bloc/settings_event.dart';
import 'package:forja/features/stats/bloc/stats_bloc.dart';
import 'package:forja/features/stats/bloc/stats_event.dart';
import 'package:forja/shared/widgets/celebration_overlay.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final missions = context.watch<MissionsBloc>().state.missions;
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
                  valueColor: const AlwaysStoppedAnimation(ForjaColors.ember),
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
                          context.read<StatsBloc>().add(
                            const StatsMissionCompleted(),
                          );
                        }
                        context.read<MissionsBloc>().add(
                          MissionToggled(mission.id),
                        );

                        // Verifica celebração após toggle
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final currentMissions = context
                              .read<MissionsBloc>()
                              .state
                              .missions;
                          final allDone =
                              currentMissions.isNotEmpty &&
                              currentMissions.every((m) => m.completed);

                          if (allDone) {
                            final settingsBloc = context.read<SettingsBloc>();
                            final settings = settingsBloc.state;
                            final today = DateTime.now()
                                .toIso8601String()
                                .substring(0, 10);

                            if (settings.lastCelebrationDate != today) {
                              settingsBloc.add(
                                SettingsCelebrationMarked(today),
                              );
                              CelebrationOverlay.show(context);
                            }
                          }
                        });
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

  final MissionEntity mission;
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
            decoration: mission.completed ? TextDecoration.lineThrough : null,
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
