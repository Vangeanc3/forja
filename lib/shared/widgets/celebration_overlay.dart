import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const CelebrationOverlay(),
    );
  }
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _cardController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _particleController;

  final List<_Particle> _particles = List.generate(20, (i) => _Particle());

  static const _subtitles = [
    "Hoje você foi disciplinado.",
    "A forja está quente.",
    "Mais um dia vencido.",
    "Ferro se torna aço assim.",
    "Sua vontade é inquebrável.",
    "Um passo de cada vez, rumo à maestria.",
    "O fogo purifica o guerreiro.",
    "Resistência é a sua marca.",
    "Você domina seus impulsos.",
    "A vitória pertence aos constantes.",
  ];

  late final String _subtitle;

  @override
  void initState() {
    super.initState();
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    _subtitle = _subtitles[dayOfYear % _subtitles.length];

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Partículas
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          // Card Central
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: ForjaColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ForjaColors.ember.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: ForjaColors.ember.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '⚔️',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Missões completas!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: ForjaColors.ember,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ForjaColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ForjaColors.ember,
                          foregroundColor: ForjaColors.onEmber,
                        ),
                        child: const Text('Continuar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double x = math.Random().nextDouble();
  final double speed = 0.5 + math.Random().nextDouble() * 0.5;
  final double size = 2 + math.Random().nextDouble() * 3;
  final double drift = (math.Random().nextDouble() - 0.5) * 0.2;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = ForjaColors.ember.withValues(alpha: 0.6);

    for (var p in particles) {
      final yProgress = (progress * p.speed) % 1.0;
      final y = size.height * (1.0 - yProgress);
      final x = size.width * (p.x + math.sin(progress * math.pi * 2) * p.drift);

      // Simular brasa/faísca com um pequeno rastro ou variação de brilho
      final alpha = (1.0 - yProgress).clamp(0.0, 1.0);
      paint.color = ForjaColors.ember.withValues(alpha: alpha * 0.7);
      
      canvas.drawCircle(Offset(x, y), p.size, paint);
      
      // Um pequeno brilho em volta da partícula
      final glowPaint = Paint()
        ..color = ForjaColors.ember.withValues(alpha: alpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), p.size * 1.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
