import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:forja/core/constants.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/features/achievements/bloc/achievements_bloc.dart';
import 'package:forja/features/auth/view/social_auth_panel.dart';
import 'package:forja/features/monk_mode/router/monk_mode_router.dart';
import 'package:forja/features/profile/router/profile_router.dart';
import 'package:forja/features/settings/bloc/settings_bloc.dart';
import 'package:forja/features/settings/bloc/settings_event.dart';
import 'package:forja/features/stats/bloc/stats_bloc.dart';
import 'package:forja/features/streak/bloc/streak_bloc.dart';
import 'package:forja/shared/widgets/ember_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsBloc>().state;
    _nameController = TextEditingController(text: settings.userName);
    _reasonController = TextEditingController(text: settings.userReason);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _modeLabel(String mode) => switch (mode) {
    ForjaMode.recruta => 'Recruta 🟡',
    ForjaMode.guerreiro => 'Guerreiro 🟠',
    ForjaMode.monge => 'Monge 🔥',
    _ => mode.toUpperCase(),
  };

  String _getLevel(int bestStreak) {
    if (bestStreak >= 90) return 'Forjado';
    if (bestStreak >= 60) return 'Lenda';
    if (bestStreak >= 30) return 'Conquistador';
    if (bestStreak >= 7) return 'Guerreiro';
    return 'Iniciante';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final stats = context.watch<StatsBloc>().state.model;
    final days = context.watch<StreakBloc>().state.days;
    final achievements = context.watch<AchievementsBloc>().state.achievements;
    final text = Theme.of(context).textTheme;

    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final totalAchievements = achievements.length;
    final level = _getLevel(stats.bestStreak);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho / Identidade
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: ForjaColors.ember,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: ForjaColors.onEmber,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Seu nome',
                    ),
                    onChanged: (val) => context.read<SettingsBloc>().add(
                      SettingsNameUpdated(val),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ForjaColors.ember.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ForjaColors.ember),
                    ),
                    child: Text(
                      'NIVEL: ${level.toUpperCase()}',
                      style: text.labelLarge?.copyWith(
                        color: ForjaColors.ember,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const SocialAuthPanel(showContainer: true),
            const SizedBox(height: 24),

            // Minha Jornada
            Text(
              'MINHA JORNADA',
              style: text.labelMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            EmberCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Por que estou aqui:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 16,
                            color: ForjaColors.ember,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Motivo da Jornada'),
                                content: TextField(
                                  controller: _reasonController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'Por que você quer mudar?',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<SettingsBloc>().add(
                                        SettingsReasonUpdated(
                                          _reasonController.text,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Salvar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Text(
                      '"${settings.userReason}"',
                      style: text.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Missão em 90 dias
            if (settings.userGoal.isNotEmpty) ...[
              Text(
                'MINHA MISSÃO EM 90 DIAS',
                style: text.labelMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              EmberCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: ForjaColors.ember,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(settings.userGoal, style: text.bodyLarge),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Estatísticas
            Text(
              'ESTATÍSTICAS',
              style: text.labelMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2,
              children: [
                _StatTile(label: 'Streak Atual', value: '$days dias'),
                _StatTile(
                  label: 'Maior Streak',
                  value: '${stats.bestStreak} dias',
                ),
                _StatTile(
                  label: 'Conquistas',
                  value: '$unlockedCount/$totalAchievements',
                ),
                _StatTile(
                  label: 'Membro desde',
                  value: stats.memberSince != null
                      ? DateFormat('dd/MM/yy').format(stats.memberSince!)
                      : '--/--/--',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Configurações
            Text(
              'CONFIGURAÇÕES',
              style: text.labelMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            EmberCard(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Modo de Jornada'),
                    subtitle: Text(_modeLabel(settings.userMode)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Text(
                                '🟡',
                                style: TextStyle(fontSize: 22),
                              ),
                              title: const Text('Recruta'),
                              subtitle: const Text(
                                'Sem pornografia. Masturbação permitida.',
                              ),
                              onTap: () {
                                context.read<SettingsBloc>().add(
                                  const SettingsModeUpdated(ForjaMode.recruta),
                                );
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Text(
                                '🟠',
                                style: TextStyle(fontSize: 22),
                              ),
                              title: const Text('Guerreiro'),
                              subtitle: const Text(
                                'Sem pornografia e sem masturbação.',
                              ),
                              onTap: () {
                                context.read<SettingsBloc>().add(
                                  const SettingsModeUpdated(
                                    ForjaMode.guerreiro,
                                  ),
                                );
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Text(
                                '🔥',
                                style: TextStyle(fontSize: 22),
                              ),
                              title: const Text('Monge'),
                              subtitle: const Text(
                                'Abstinência total. Transformação completa.',
                              ),
                              onTap: () {
                                context.read<SettingsBloc>().add(
                                  const SettingsModeUpdated(ForjaMode.monge),
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Notificações Diárias'),
                    subtitle: const Text('Lembretes de força e propósito'),
                    value: settings.notificationsEnabled,
                    activeThumbColor: ForjaColors.ember,
                    onChanged: (val) => context.read<SettingsBloc>().add(
                      SettingsNotificationsUpdated(val),
                    ),
                  ),
                  if (settings.notificationsEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Horário da Notificação'),
                      subtitle: Text(
                        '${settings.notificationHour.toString().padLeft(2, '0')}:00',
                      ),
                      trailing: const Icon(
                        Icons.access_time,
                        color: ForjaColors.ember,
                      ),
                      onTap: () async {
                        final settingsBloc = context.read<SettingsBloc>();
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: settings.notificationHour,
                            minute: 0,
                          ),
                        );
                        if (time != null) {
                          settingsBloc.add(
                            SettingsNotificationHourUpdated(time.hour),
                          );
                        }
                      },
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Modo Monge'),
                    subtitle: const Text('Gerenciar restrições extras'),
                    trailing: const Icon(
                      Icons.security_rounded,
                      color: ForjaColors.ember,
                    ),
                    onTap: () => context.push(MonkModeRouter.initial),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Contato de Apoio'),
                    subtitle: const Text(
                      'Pessoa de confiança para emergências',
                    ),
                    trailing: const Icon(
                      Icons.contact_phone_outlined,
                      color: ForjaColors.ember,
                    ),
                    onTap: () => context.push(ProfileRouter.supportContact),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Horários de Risco'),
                    subtitle: const Text('Alertas em momentos vulneráveis'),
                    trailing: const Icon(
                      Icons.alarm_on_rounded,
                      color: ForjaColors.ember,
                    ),
                    onTap: () => context.push(ProfileRouter.riskHours),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return EmberCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white60),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ForjaColors.ember,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
