import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/notification_service.dart';
import '../../core/theme.dart';
import '../../data/providers/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  String _selectedMode = ForjaMode.nofap;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _nextPage() => _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

  Future<void> _start() async {
    await NotificationService.requestPermission();
    await ref.read(settingsRepositoryProvider).completeOnboarding(
          name: _nameController.text.trim(),
          mode: _selectedMode,
          reason: _reasonController.text.trim(),
        );
    await ref.read(streakProvider.notifier).start();
    await ref.read(statsProvider.notifier).setMemberSince(DateTime.now());
    await NotificationService.scheduleAll();
    if (mounted) context.go(ForjaRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => _Dot(active: i == _currentPage),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomeSlide(
                    nameController: _nameController,
                    reasonController: _reasonController,
                    onNext: _nextPage,
                  ),
                  _ModeSlide(
                    selectedMode: _selectedMode,
                    onModeChanged: (m) => setState(() => _selectedMode = m),
                    onNext: _nextPage,
                  ),
                  _CommitSlide(onStart: _start),
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

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide({
    required this.nameController,
    required this.reasonController,
    required this.onNext,
  });

  final TextEditingController nameController;
  final TextEditingController reasonController;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔥', style: text.displayLarge?.copyWith(fontSize: 56)),
            const SizedBox(height: 24),
            Text('Bem-vindo à\nForja.', style: text.displayMedium),
            const SizedBox(height: 8),
            Text('O processo começa com um nome.', style: text.bodyLarge),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              style: text.titleLarge,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Seu nome',
                hintStyle:
                    text.titleLarge?.copyWith(color: ForjaColors.textSecondary),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: ForjaColors.divider, width: 1.5),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: ForjaColors.ember, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Por que você quer mudar?', style: text.bodyLarge),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              style: text.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Ex: Para ser o homem que minha família merece',
                hintStyle:
                    text.bodyMedium?.copyWith(color: ForjaColors.textSecondary),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: ForjaColors.divider, width: 1.5),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: ForjaColors.ember, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 48),
            FilledButton(onPressed: onNext, child: const Text('PRÓXIMO')),
          ],
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Escolha\nseu modo.', style: text.displayMedium),
          const Spacer(),
          _ModeCard(
            title: 'NoFap',
            subtitle: 'Sem Pornografia, Masturbação ou Orgasmo',
            icon: '🔥',
            selected: selectedMode == ForjaMode.nofap,
            onTap: () => onModeChanged(ForjaMode.nofap),
          ),
          const SizedBox(height: 16),
          _ModeCard(
            title: 'Modo Monge',
            subtitle: 'Abstinência total — foco e potência máxima',
            icon: '⚔️',
            selected: selectedMode == ForjaMode.monk,
            onTap: () => onModeChanged(ForjaMode.monk),
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
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? ForjaColors.ember.withValues(alpha: 0.1)
              : ForjaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? ForjaColors.ember : ForjaColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommitSlide extends StatelessWidget {
  const _CommitSlide({required this.onStart});

  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚔️', style: text.displayLarge?.copyWith(fontSize: 56)),
          const SizedBox(height: 24),
          Text('Hora do\ncompromisso.', style: text.displayMedium),
          const SizedBox(height: 16),
          Text(
            'A forja não mente.\n'
            'Cada dia é uma escolha de quem você quer ser.\n\n'
            'Você está aqui porque sabe que é capaz de mais.',
            style: text.bodyLarge?.copyWith(height: 1.6),
          ),
          const Spacer(),
          // Aviso de notificação antes da permissão nativa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: ForjaColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ForjaColors.divider),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: ForjaColors.ember,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lembretes diários às 8h para manter o foco',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => onStart(),
            child: const Text('COMEÇAR MINHA FORJA'),
          ),
        ],
      ),
    );
  }
}
