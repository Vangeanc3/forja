import 'package:flutter/material.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/shared/widgets/sword_widget.dart';
import 'social_auth_panel.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRIAR CONTA'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const SizedBox(
                width: 100,
                child: SwordWidget(days: 90, showLabel: false),
              ),
              const SizedBox(height: 24),
              Text(
                'FORJA',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: ForjaColors.ember,
                      letterSpacing: 8,
                      fontSize: 32,
                    ),
              ),
              const SizedBox(height: 48),
              const SocialAuthPanel(
                showContainer: true,
                forceSignUp: true,
                showTitle: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
