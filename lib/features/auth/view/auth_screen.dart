import 'package:flutter/material.dart';

import 'social_auth_panel.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conta')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: SocialAuthPanel(showContainer: true),
        ),
      ),
    );
  }
}
