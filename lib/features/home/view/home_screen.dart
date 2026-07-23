import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:forja/core/constants.dart';
import 'package:forja/core/quotes.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/domain/entities/weekly_challenge_entity.dart';
import 'package:forja/features/home/bloc/home_bloc.dart';
import 'package:forja/features/home/bloc/home_event.dart';
import 'package:forja/features/journal/view/journal_screen.dart';
import 'package:forja/features/journal/bloc/journal_bloc.dart';
import 'package:forja/features/missions/view/missions_screen.dart';
import 'package:forja/features/monk_mode/bloc/monk_mode_bloc.dart';
import 'package:forja/features/profile/router/profile_router.dart';
import 'package:forja/features/relapse/router/relapse_router.dart';
import 'package:forja/features/settings/bloc/settings_bloc.dart';
import 'package:forja/features/settings/bloc/settings_event.dart';
import 'package:forja/features/stats/bloc/stats_bloc.dart';
import 'package:forja/features/stats/bloc/weekly_report_bloc.dart';
import 'package:forja/features/stats/bloc/weekly_report_event.dart';
import 'package:forja/features/stats/router/stats_router.dart';
import 'package:forja/features/streak/bloc/streak_bloc.dart';
import 'package:forja/features/tasks/view/tasks_screen.dart';
import 'package:forja/features/urgency/router/urgency_router.dart';
import 'package:forja/features/weekly_challenge/bloc/weekly_challenge_bloc.dart';
import 'package:forja/features/weekly_challenge/router/weekly_challenge_router.dart';
import 'package:forja/shared/widgets/sword_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDailyQuotePopup());
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _quoteFor(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ForjaQuotes.list[dayOfYear % ForjaQuotes.list.length];
  }

  Future<void> _showDailyQuotePopup() async {
    if (!mounted) return;

    final settingsBloc = context.read<SettingsBloc>();
    final settings = settingsBloc.state;
    final today = _dateKey(DateTime.now());
    if (settings.lastDailyQuotePopupDate == today) return;

    settingsBloc.add(SettingsDailyQuotePopupMarked(today));
    if (!mounted) return;

    final text = Theme.of(context).textTheme;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ForjaColors.surface,
        title: Text(
          'Mensagem do dia',
          style: text.titleLarge?.copyWith(color: ForjaColors.ember),
        ),
        content: Text(
          _quoteFor(DateTime.now()),
          style: text.bodyLarge?.copyWith(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ENTENDI'),
          ),
        ],
      ),
    );
  }

  void _checkAndGenerateWeeklyReport() {
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return;

    final streak = context.read<StreakBloc>().state.days;
    final isMonk = context.read<MonkModeBloc>().state.active;
    final challengeDone = context.read<WeeklyChallengeBloc>().state.accepted;
    final journalEntries = context.read<JournalBloc>().state.entries;
    final stats = context.read<StatsBloc>().state.model;

    final weeklyReportBloc = context.read<WeeklyReportBloc>();
    Future.microtask(
      () => weeklyReportBloc.add(
        WeeklyCurrentReportGenerated(
          cleanDaysThisWeek: streak >= 7 ? 7 : streak,
          missionsDoneThisWeek: stats.totalMissionsDone,
          challengeCompleted: challengeDone,
          monkModeActive: isMonk,
          journalEntries: journalEntries.map((e) => e.content).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = context.watch<StreakBloc>().state.days;
    final settings = context.watch<SettingsBloc>().state;
    final selectedIndex = context.watch<HomeBloc>().state.selectedIndex;
    final challengeState = context.watch<WeeklyChallengeBloc>().state;
    final challengeAccepted = challengeState.accepted;
    final challenge = challengeState.challenge;
    final pages = [
      _HomeDashboard(
        days: days,
        challenge: challenge,
        challengeAccepted: challengeAccepted,
        onWeeklyChallengeTap: () => context.push(WeeklyChallengeRouter.initial),
        onUrgencyTap: () => context.push(UrgencyRouter.initial),
        onRelapseTap: () => context.push(RelapseRouter.initial),
      ),
      const MissionsScreen(),
      const ProgressAreasScreen(),
      const JournalScreen(),
    ];

    // Lógica para gerar relatório se for domingo e ainda não existir
    _checkAndGenerateWeeklyReport();

    return Scaffold(
      appBar: selectedIndex == 0
          ? _HomeAppBar(
              userName: settings.userName,
              onStatsTap: () => context.push(StatsRouter.initial),
            )
          : null,
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: ForjaColors.textSecondary,
        iconSize: 30,
        backgroundColor: ForjaColors.surface,
        currentIndex: selectedIndex,
        onTap: (index) => context.read<HomeBloc>().add(HomeTabChanged(index)),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: 'Missões',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph_rounded),
            label: 'Evolução',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: 'Diário',
          ),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.days,
    required this.challenge,
    required this.challengeAccepted,
    required this.onWeeklyChallengeTap,
    required this.onUrgencyTap,
    required this.onRelapseTap,
  });

  final int days;
  final WeeklyChallengeEntity challenge;
  final bool challengeAccepted;
  final VoidCallback onWeeklyChallengeTap;
  final VoidCallback onUrgencyTap;
  final VoidCallback onRelapseTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              _SwordHero(days: days),
              const SizedBox(height: 12),
              _WeeklyChallengeCard(
                challenge: challenge,
                isAccepted: challengeAccepted,
                onTap: onWeeklyChallengeTap,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    FilledButton(
                      onPressed: onUrgencyTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: ForjaColors.ember,
                        foregroundColor: ForjaColors.onEmber,
                      ),
                      child: const Text('ESTOU COM VONTADE'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: onRelapseTap,
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
    );
  }
}

class _SwordHero extends StatelessWidget {
  const _SwordHero({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 124,
        height: 246,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SwordWidget(days: days, showLabel: true),
        ),
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({required this.userName, required this.onStatsTap});

  final String userName;
  final VoidCallback onStatsTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 50);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      actions: const [SizedBox.shrink()],
      flexibleSpace: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          top: kToolbarHeight - 12,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                _ProfileAvatar(
                  onTap: () => context.push(ProfileRouter.initial),
                ),
                const SizedBox(width: 16),
                Expanded(child: _WelcomeText(userName: userName)),
                const SizedBox(width: 8),
                _HeaderActionButton(
                  tooltip: 'Progresso',
                  onPressed: onStatsTap,
                  icon: Icons.trending_up_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: ForjaColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: ForjaColors.divider),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        color: ForjaColors.ember,
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ForjaColors.surface,
          border: Border.all(color: ForjaColors.divider),
        ),
        child: const Icon(
          Icons.person_outline_rounded,
          color: ForjaColors.ember,
          size: 30,
        ),
      ),
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText({required this.userName});

  final String userName;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Bom dia';
    if (hour >= 12 && hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final displayName = userName.trim().isNotEmpty
        ? userName.trim()
        : ForjaStrings.appName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_greeting()},',
          style: text.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          displayName,
          style: text.bodyLarge?.copyWith(
            color: ForjaColors.ember,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _WeeklyChallengeCard extends StatelessWidget {
  const _WeeklyChallengeCard({
    required this.challenge,
    required this.isAccepted,
    required this.onTap,
  });

  final WeeklyChallengeEntity challenge;
  final bool isAccepted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
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
                    color: isAccepted
                        ? ForjaColors.ember
                        : ForjaColors.textSecondary,
                  ),
                ),
                if (isAccepted)
                  const Icon(
                    Icons.verified_rounded,
                    color: ForjaColors.ember,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              challenge.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              isAccepted
                  ? 'Em progresso...'
                  : 'Toque para ver detalhes e aceitar',
              style: text.bodySmall?.copyWith(color: ForjaColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
