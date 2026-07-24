import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:forja/core/constants.dart';
import 'package:forja/core/notification_service.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/features/home/router/home_router.dart';
import 'package:forja/features/monk_mode/router/monk_mode_router.dart';
import 'package:forja/features/settings/bloc/settings_bloc.dart';
import 'package:forja/features/settings/bloc/settings_event.dart';
import 'package:forja/features/stats/bloc/stats_bloc.dart';
import 'package:forja/features/stats/bloc/stats_event.dart';
import 'package:forja/features/streak/bloc/streak_bloc.dart';
import 'package:forja/features/streak/bloc/streak_event.dart';
import 'package:forja/shared/widgets/sword_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  String _selectedMode = ForjaMode.recruta;
  int _currentPage = 0;
  String? _selectedReason;
  String? _selectedGoal;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() => _pageController.nextPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  void _prevPage() => _pageController.previousPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  Future<void> _start() async {
    final settingsBloc = context.read<SettingsBloc>();
    final streakBloc = context.read<StreakBloc>();
    final statsBloc = context.read<StatsBloc>();
    final router = GoRouter.of(context);

    await NotificationService.requestPermission();
    settingsBloc.add(
      SettingsOnboardingCompleted(
        name: _nameController.text.trim(),
        mode: _selectedMode,
        reason: _selectedReason ?? '',
        goal: _selectedGoal ?? '',
      ),
    );
    streakBloc.add(const StreakStarted());
    statsBloc.add(StatsMemberSinceSet(DateTime.now()));

    if (!mounted) return;
    final isMonge = _selectedMode == ForjaMode.monge;
    router.go(HomeRouter.initial);
    if (isMonge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(MonkModeRouter.initial);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const totalPages = 5;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: ForjaColors.textPrimary,
                      onPressed: _prevPage,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        totalPages,
                        (i) => _Dot(active: i == _currentPage),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomeSlide(onNext: _nextPage),
                  _NameSlide(
                    nameController: _nameController,
                    onNext: _nextPage,
                  ),
                  _ReasonsSlide(
                    selectedReason: _selectedReason,
                    onSelect: (r) => setState(() => _selectedReason = r),
                    onNext: _nextPage,
                  ),
                  _ModeSlide(
                    selectedMode: _selectedMode,
                    onModeChanged: (m) => setState(() => _selectedMode = m),
                    onNext: _nextPage,
                  ),
                  _GoalsSlide(
                    selectedGoal: _selectedGoal,
                    onSelect: (g) => setState(() => _selectedGoal = g),
                    onStart: _start,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? ForjaColors.ember
            : ForjaColors.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Slide 1: Boas-vindas ──────────────────────────────────────────────────────

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Center(
            child: SizedBox(
              width: 120,
              child: SwordWidget(days: 90, showLabel: false),
            ),
          ),
          const SizedBox(height: 48),
          Text('Bem-vindo à\nForja', style: text.displayMedium),
          const SizedBox(height: 12),
          Text(
            'O lugar onde homens são feitos.',
            style: text.bodyLarge?.copyWith(color: ForjaColors.textSecondary),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            child: const Text('COMEÇAR'),
          ),
        ],
      ),
    );
  }
}

// ── Slide 2: Nome ─────────────────────────────────────────────────────────────

class _NameSlide extends StatelessWidget {
  const _NameSlide({required this.nameController, required this.onNext});

  final TextEditingController nameController;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Como você\nse chama?', style: text.displayMedium),
          const SizedBox(height: 40),
          TextField(
            controller: nameController,
            style: text.titleLarge,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Seu nome',
              hintStyle: text.titleLarge?.copyWith(
                color: ForjaColors.textSecondary,
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: ForjaColors.divider, width: 1.5),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: ForjaColors.ember, width: 2),
              ),
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: nameController,
            builder: (_, value, _) => FilledButton(
              onPressed: value.text.trim().isNotEmpty ? onNext : null,
              child: const Text('PRÓXIMO'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide 3: Identificação (seleção única) ────────────────────────────────────

class _ReasonsSlide extends StatelessWidget {
  const _ReasonsSlide({
    required this.selectedReason,
    required this.onSelect,
    required this.onNext,
  });

  final String? selectedReason;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  static const _reasons = [
    ('🔴', 'Pornografia está controlando minha vida'),
    ('🟠', 'Quero mais energia e foco'),
    ('🟡', 'Quero me reconectar com pessoas reais'),
    ('🟢', 'Quero ser uma versão melhor de mim'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('O que te\ntrouxe aqui?', style: text.displayMedium),
          const SizedBox(height: 28),
          ..._reasons.map((r) {
            final isSelected = selectedReason == r.$2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onSelect(r.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ForjaColors.ember.withValues(alpha: 0.08)
                        : ForjaColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? ForjaColors.ember
                          : ForjaColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(r.$1, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Expanded(child: Text(r.$2, style: text.bodyLarge)),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: ForjaColors.ember,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          FilledButton(
            onPressed: selectedReason != null ? onNext : null,
            child: const Text('PRÓXIMO'),
          ),
        ],
      ),
    );
  }
}

// ── Slide 4: Modo (single-select) ─────────────────────────────────────────────

class _ModeSlide extends StatelessWidget {
  const _ModeSlide({
    required this.selectedMode,
    required this.onModeChanged,
    required this.onNext,
  });

  final String selectedMode;
  final ValueChanged<String> onModeChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Qual é o seu\ncompromisso?', style: text.displayMedium),
          const Spacer(),
          _ModeCard(
            emoji: '🟡',
            title: 'Recruta',
            subtitle: 'Sem pornografia. Masturbação permitida.',
            accentColor: const Color(0xFFD4A800),
            selected: selectedMode == ForjaMode.recruta,
            onTap: () => onModeChanged(ForjaMode.recruta),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            emoji: '🟠',
            title: 'Guerreiro',
            subtitle:
                'Sem pornografia e sem masturbação. Controle total do impulso.',
            accentColor: ForjaColors.ember,
            selected: selectedMode == ForjaMode.guerreiro,
            onTap: () => onModeChanged(ForjaMode.guerreiro),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            emoji: '🔥',
            title: 'Monge',
            subtitle:
                'Abstinência total. Porn, masturbação e vícios extras. Transformação completa.',
            accentColor: const Color(0xFFCC2233),
            selected: selectedMode == ForjaMode.monge,
            onTap: () => onModeChanged(ForjaMode.monge),
          ),
          const Spacer(),
          FilledButton(onPressed: onNext, child: const Text('PRÓXIMO')),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.1)
              : ForjaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accentColor : ForjaColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleLarge?.copyWith(
                      color: selected ? accentColor : ForjaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: text.bodyMedium),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: accentColor, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Slide 5: Quem você quer ser (seleção única) ───────────────────────────────

class _GoalsSlide extends StatelessWidget {
  const _GoalsSlide({
    required this.selectedGoal,
    required this.onSelect,
    required this.onStart,
  });

  final String? selectedGoal;
  final ValueChanged<String> onSelect;
  final Future<void> Function() onStart;

  static const _goals = [
    ('⚔️', 'Um homem com disciplina de ferro'),
    ('🧠', 'Alguém com foco e clareza mental'),
    ('💑', 'Presente e conectado no meu relacionamento'),
    ('💪', 'Com energia e disposição todos os dias'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quem você quer\nser em 90 dias?', style: text.displayMedium),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: _goals.map((g) {
                final isSelected = selectedGoal == g.$2;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => onSelect(g.$2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ForjaColors.ember.withValues(alpha: 0.08)
                            : ForjaColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? ForjaColors.ember
                              : ForjaColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(g.$1, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(child: Text(g.$2, style: text.bodyLarge)),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: ForjaColors.ember,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: selectedGoal != null ? () => onStart() : null,
            child: const Text('COMEÇAR MINHA FORJA'),
          ),
        ],
      ),
    );
  }
}
