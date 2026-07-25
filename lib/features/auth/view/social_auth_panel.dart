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
  bool _showEmailLink = false; // Adicionado aqui

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) async {
        if (!context.mounted) return;
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
              if (!context.mounted) return;
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
            state.isAuthenticated &&
            !widget.redirectOnSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Conta vinculada com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          if (mounted) {
            setState(() {
              _showEmailLink = false;
            });
          }
        }

        if (state.submissionStatus == AuthSubmissionStatus.success &&
            !state.isAuthenticated) {
          setState(() => _isSyncing = true);
          try {
            await context.read<LocalRemoteSyncService>().clearAllLocalData();
            if (!context.mounted) return;
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
                showEmailLink: _showEmailLink,
                onShowEmailLinkChanged: (val) => setState(() => _showEmailLink = val),
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

class _ConnectedAccount extends StatefulWidget {
  const _ConnectedAccount({
    required this.user,
    required this.loading,
    required this.compact,
    required this.showEmailLink,
    required this.onShowEmailLinkChanged,
  });

  final AuthUserEntity user;
  final bool loading;
  final bool compact;
  final bool showEmailLink;
  final ValueChanged<bool> onShowEmailLinkChanged;

  @override
  State<_ConnectedAccount> createState() => _ConnectedAccountState();
}

class _ConnectedAccountState extends State<_ConnectedAccount> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showSignOutConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Dispositivo'),
        content: Text(
          widget.user.isGuest
              ? 'Atenção: Você está usando uma conta de convidado sem nenhum método de login vinculado. '
                  'Se sair agora deste dispositivo, você poderá perder o acesso aos seus dados.'
              : 'Deseja realmente encerrar sua sessão neste dispositivo? '
                  'Sua conta e progresso continuarão salvos com segurança na nuvem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (!context.mounted) return;
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: widget.compact ? 18 : 22,
              backgroundColor: ForjaColors.ember.withValues(alpha: 0.18),
              child: Icon(
                _providerIcon(widget.user.providerLabel),
                color: ForjaColors.ember,
                size: widget.compact ? 18 : 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.user.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (widget.user.hasGoogleProvider)
                        _ProviderChip(
                          icon: Icons.g_mobiledata_rounded,
                          label: 'Google',
                        ),
                      if (widget.user.hasPasswordProvider)
                        _ProviderChip(
                          icon: Icons.email_outlined,
                          label: 'E-mail',
                        ),
                      if (widget.user.isAnonymous &&
                          !widget.user.hasGoogleProvider &&
                          !widget.user.hasPasswordProvider)
                        _ProviderChip(
                          icon: Icons.person_outline,
                          label: 'Convidado',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: widget.loading
                  ? null
                  : () => _showSignOutConfirmation(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sair'),
            ),
          ],
        ),
        if (!widget.user.hasGoogleProvider ||
            !widget.user.hasPasswordProvider) ...[
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Facilite seu login vinculando outras opções:',
                  style: text.bodySmall?.copyWith(
                    color: ForjaColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!widget.user.hasGoogleProvider)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.loading
                        ? null
                        : () => context
                            .read<AuthBloc>()
                            .add(const AuthGoogleSignInRequested()),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                    label: const Text('Vincular Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              if (!widget.user.hasGoogleProvider &&
                  !widget.user.hasPasswordProvider)
                const SizedBox(width: 8),
              if (!widget.user.hasPasswordProvider)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.loading
                        ? null
                        : () => widget.onShowEmailLinkChanged(!widget.showEmailLink),
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('Vincular E-mail'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
            ],
          ),
          if (widget.showEmailLink) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail para vincular',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Crie uma senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: widget.loading ? null : _submitEmailLink,
              child: Text(widget.loading ? 'Vinculando...' : 'Confirmar Vínculo'),
            ),
          ],
        ],
      ],
    );
  }

  void _submitEmailLink() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha e-mail e senha')),
      );
      return;
    }

    context.read<AuthBloc>().add(AuthLinkEmailPasswordRequested(email, password));
  }

  IconData _providerIcon(String providerLabel) {
    if (providerLabel.contains('Google')) return Icons.g_mobiledata_rounded;
    return Icons.verified_user_outlined;
  }
}

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ForjaColors.ember.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: ForjaColors.ember.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ForjaColors.ember),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ForjaColors.ember,
            ),
          ),
        ],
      ),
    );
  }
}
