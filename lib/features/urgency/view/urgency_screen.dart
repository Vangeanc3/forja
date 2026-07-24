import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/features/profile/router/profile_router.dart';
import 'package:forja/features/settings/bloc/settings_bloc.dart';

class UrgencyScreen extends StatefulWidget {
  const UrgencyScreen({super.key});

  @override
  State<UrgencyScreen> createState() => _UrgencyScreenState();
}

class _UrgencyScreenState extends State<UrgencyScreen> {
  bool _showingBreathing = false;
  bool _showingDistractions = false;
  bool _showingTimer = false;

  void _callSupport() async {
    final settings = context.read<SettingsBloc>().state;
    final phone = settings.supportContactPhone;
    final name = settings.supportContactName;

    if (phone == null || phone.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contato de Apoio'),
          content: const Text(
            'Você ainda não cadastrou um contato de confiança.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('AGORA NÃO'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(ProfileRouter.supportContact);
              },
              child: const Text('CADASTRAR'),
            ),
          ],
        ),
      );
      return;
    }

    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível ligar para $name')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Urgência')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _showingBreathing
            ? const _GuidedBreathing()
            : _showingDistractions
            ? const _DistractionsList()
            : _showingTimer
            ? const _EmergencyTimer()
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Respire fundo. Você é mais forte que esse impulso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _UrgencyOption(
                      icon: Icons.air_rounded,
                      title: 'Respiração Guiada',
                      subtitle: 'Acalme sua mente e retome o controle',
                      onTap: () => setState(() => _showingBreathing = true),
                    ),
                    const SizedBox(height: 24),
                    _UrgencyOption(
                      icon: Icons.list_rounded,
                      title: 'Lista de Distrações',
                      subtitle: 'Mude o foco agora mesmo',
                      onTap: () => setState(() => _showingDistractions = true),
                    ),
                    const SizedBox(height: 24),
                    _UrgencyOption(
                      icon: Icons.timer_outlined,
                      title: 'Aguenta 10 minutos',
                      subtitle: 'Vença essa batalha um passo por vez',
                      onTap: () => setState(() => _showingTimer = true),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _callSupport,
                        icon: const Icon(Icons.phone),
                        label: const Text(
                          'LIGAR AGORA',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _UrgencyOption extends StatelessWidget {
  const _UrgencyOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ForjaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ForjaColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: ForjaColors.ember, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: ForjaColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: ForjaColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidedBreathing extends StatefulWidget {
  const _GuidedBreathing();

  @override
  State<_GuidedBreathing> createState() => _GuidedBreathingState();
}

class _GuidedBreathingState extends State<_GuidedBreathing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _cycle = 0;
  String _text = 'Inspira';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _runAnimation();
  }

  Future<void> _runAnimation() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      setState(() {
        _cycle = i + 1;
        _text = 'Inspira';
      });
      await _controller.forward();

      if (!mounted) return;
      setState(() => _text = 'Segura');
      await Future.delayed(const Duration(seconds: 4));

      if (!mounted) return;
      setState(() => _text = 'Expira');
      await _controller.reverse();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Muito bem. O controle é seu.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Ciclo $_cycle de 3',
            style: const TextStyle(color: ForjaColors.textSecondary),
          ),
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 200 + (100 * _controller.value),
                height: 200 + (100 * _controller.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ForjaColors.ember.withValues(
                    alpha: 0.1 + (0.2 * _controller.value),
                  ),
                  border: Border.all(color: ForjaColors.ember, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: ForjaColors.ember.withValues(alpha: 0.3),
                      blurRadius: 20 * _controller.value,
                      spreadRadius: 5 * _controller.value,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ForjaColors.ember,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DistractionsList extends StatelessWidget {
  const _DistractionsList();

  static const List<String> _distractions = [
    'Faz 20 flexões agora',
    'Toma um banho frio',
    'Sai pra caminhar 10 minutos',
    'Liga pra alguém',
    'Bebe um copo d\'água e espera 5 minutos',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escolha uma e faça AGORA:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ..._distractions.map(
          (d) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.bolt_rounded, color: ForjaColors.ember),
                title: Text(d),
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmergencyTimer extends StatefulWidget {
  const _EmergencyTimer();

  @override
  State<_EmergencyTimer> createState() => _EmergencyTimerState();
}

class _EmergencyTimerState extends State<_EmergencyTimer>
    with SingleTickerProviderStateMixin {
  int _secondsRemaining = 600; // 10 minutes
  Timer? _timer;
  bool _isCompleted = false;
  late AnimationController _confettiController;

  final List<String> _encouragements = [
    "Resista. A vontade é passageira, sua força é eterna.",
    "Cada segundo conta. Você está no comando.",
    "O impulso é uma onda. Deixe-a passar sem te derrubar.",
    "Você já venceu batalhas maiores que esta.",
    "Faltam só mais alguns minutos. Aguenta firme!",
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        setState(() => _isCompleted = true);
        _confettiController.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  String get _timerText {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  String get _currentEncouragement {
    if (_isCompleted) return "Você venceu essa batalha!";
    // Mudar a cada 2 minutos (120s)
    int index = (600 - _secondsRemaining) ~/ 120;
    if (index >= _encouragements.length) index = _encouragements.length - 1;
    return _encouragements[index];
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (_isCompleted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _confettiController,
                curve: Curves.elasticOut,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: ForjaColors.ember,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'VITÓRIA!',
              style: text.displayMedium?.copyWith(color: ForjaColors.ember),
            ),
            const SizedBox(height: 8),
            Text('Você venceu essa batalha.', style: text.bodyLarge),
            const SizedBox(height: 48),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('VOLTAR'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _timerText,
            style: text.displayLarge?.copyWith(
              fontSize: 80,
              color: ForjaColors.ember,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _currentEncouragement,
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 64),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: _secondsRemaining / 600,
              backgroundColor: ForjaColors.divider,
              color: ForjaColors.ember,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Se precisar sair, tudo bem.\nSem julgamentos.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: ForjaColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
