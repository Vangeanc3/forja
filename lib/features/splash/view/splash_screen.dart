import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:forja/core/theme.dart';
import 'package:forja/features/home/router/home_router.dart';
import 'package:forja/features/onboarding/router/onboarding_router.dart';
import 'package:forja/shared/widgets/sword_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.showOnboarding});

  final bool showOnboarding;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      context.go(
        widget.showOnboarding ? OnboardingRouter.initial : HomeRouter.initial,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ForjaColors.background,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 120,
                child: SwordWidget(days: 90, showLabel: false),
              ),
              const SizedBox(height: 36),
              Text(
                'FORJA',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: ForjaColors.ember,
                  letterSpacing: 14,
                  fontSize: 44,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
