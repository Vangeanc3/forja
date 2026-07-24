import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:forja/features/onboarding/router/onboarding_router.dart';
import 'package:forja/features/home/router/home_router.dart';
import 'package:forja/data/repositories/settings_repository.dart';
import 'package:forja/data/services/local_remote_sync_service.dart';

import '../../../core/theme.dart';
import '../../../domain/entities/auth_user_entity.dart';
import '../../../shared/widgets/ember_card.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../router/auth_router.dart';

class SocialAuthPanel extends StatefulWidget {
  const SocialAuthPanel({
    super.key,
    this.compact = false,
    this.showContainer = true,
    this.showTitle = true,
    this.redirectOnSuccess = true,
    this.forceSignUp,
  });

  final bool compact;
  final bool showContainer;
  final bool showTitle;
  final bool redirectOnSuccess;
  final bool? forceSignUp;

  @override
  State<SocialAuthPanel> createState() => _SocialAuthPanelState();
}

class _SocialAuthPanelState extends State<SocialAuthPanel> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) async {
        if (state.submissionStatus == AuthSubmissionStatus.failure) {
          final message = state.errorMessage;
          if (message == null || message.isEmpty) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
          return;
        }

        if (state.submissionStatus == AuthSubmissionStatus.success &&
            state.isAuthenticated &&
            widget.redirectOnSuccess) {
          final settings = context.read<SettingsRepository>();

          if (!settings.onboardingDone) {
            setState(() => _isSyncing = true);
            try {
              await context.read<LocalRemoteSyncService>().syncAll();
            } finally {
              if (mounted) setState(() => _isSyncing = false);
            }
          }

          if (!mounted) return;

          if (settings.onboardingDone) {
            context.go(HomeRouter.initial);
          } else {
            context.go(OnboardingRouter.initial);
          }
        }

        if (state.submissionStatus == AuthSubmissionStatus.success &&
            !state.isAuthenticated) {
          setState(() => _isSyncing = true);
          try {
            await context.read<LocalRemoteSyncService>().clearAllLocalData();
          } finally {
            if (mounted) setState(() => _isSyncing = false);
          }

          if (!mounted) return;
          context.go(AuthRouter.initial);
        }
      },
      builder: (context, state) {
        final content = state.isAuthenticated
            ? _ConnectedAccount(
                user: state.user!,
                loading: state.isLoading || _isSyncing,
                compact: widget.compact,
              )
            : _SignInActions(
                compact: widget.compact,
                loading: state.isLoading || _isSyncing,
                showTitle: widget.showTitle,
                forceSignUp: widget.forceSignUp,
              );

        if (!widget.showContainer) return content;

        return EmberCard(
          padding: EdgeInsets.all(widget.compact ? 14 : 16),
          child: content,
        );
      },
    );
  }
}

class _SignInActions extends StatefulWidget {
  const _SignInActions({
    required this.compact,
    required this.loading,
    required this.showTitle,
    this.forceSignUp,
  });

  final bool compact;
  final bool loading;
  final bool showTitle;
  final bool? forceSignUp;

  @override
  State<_SignInActions> createState() => _SignInActionsState();
}

class _SignInActionsState extends State<_SignInActions> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isSignUp;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.forceSignUp ?? false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTitle) ...[
          Text(
            _isSignUp ? 'CRIAR CONTA' : 'ENTRAR',
            style: text.labelMedium?.copyWith(color: ForjaColors.textSecondary),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Senha',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: widget.loading ? null : _submit,
          child: Text(
            widget.loading
                ? 'Processando...'
                : (_isSignUp ? 'Criar Conta' : 'Entrar'),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.loading
              ? null
              : () => context.read<AuthBloc>().add(
                  const AuthGoogleSignInRequested(),
                ),
          icon: widget.loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.g_mobiledata_rounded, size: 28),
          label: Text(widget.loading ? 'Conectando...' : 'Entrar com Google'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            if (widget.forceSignUp != null) {
              if (widget.forceSignUp!) {
                context.pushReplacement(AuthRouter.initial);
              } else {
                context.pushReplacement(AuthRouter.register);
              }
            } else {
              setState(() => _isSignUp = !_isSignUp);
            }
          },
          child: Text(
            _isSignUp
                ? 'Já tem uma conta? Entre aqui'
                : 'Não tem conta? Cadastre-se',
          ),
        ),
      ],
    );
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha e-mail e senha')),
      );
      return;
    }

    if (_isSignUp) {
      context.read<AuthBloc>().add(AuthEmailPasswordSignUpRequested(email, password));
    } else {
      context.read<AuthBloc>().add(AuthEmailPasswordSignInRequested(email, password));
    }
  }
}

class _ConnectedAccount extends StatelessWidget {
  const _ConnectedAccount({
    required this.user,
    required this.loading,
    required this.compact,
  });

  final AuthUserEntity user;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final subtitle = user.email?.trim().isNotEmpty == true
        ? '${user.providerLabel} - ${user.email}'
        : user.providerLabel;

    return Row(
      children: [
        CircleAvatar(
          radius: compact ? 18 : 22,
          backgroundColor: ForjaColors.ember.withValues(alpha: 0.18),
          child: Icon(
            _providerIcon(user.providerLabel),
            color: ForjaColors.ember,
            size: compact ? 18 : 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                  color: ForjaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: loading
              ? null
              : () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Sair'),
        ),
      ],
    );
  }

  IconData _providerIcon(String providerLabel) => switch (providerLabel) {
    'Google' => Icons.g_mobiledata_rounded,
    _ => Icons.verified_user_outlined,
  };
}
