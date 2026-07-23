import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme.dart';
import '../../../domain/entities/auth_user_entity.dart';
import '../../../shared/widgets/ember_card.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SocialAuthPanel extends StatelessWidget {
  const SocialAuthPanel({
    super.key,
    this.compact = false,
    this.showContainer = true,
    this.showTitle = true,
  });

  final bool compact;
  final bool showContainer;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus != AuthSubmissionStatus.failure) return;
        final message = state.errorMessage;
        if (message == null || message.isEmpty) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        final content = state.isAuthenticated
            ? _ConnectedAccount(
                user: state.user!,
                loading: state.isLoading,
                compact: compact,
              )
            : _SignInActions(
                compact: compact,
                loading: state.isLoading,
                showTitle: showTitle,
              );

        if (!showContainer) return content;

        return EmberCard(
          padding: EdgeInsets.all(compact ? 14 : 16),
          child: content,
        );
      },
    );
  }
}

class _SignInActions extends StatelessWidget {
  const _SignInActions({
    required this.compact,
    required this.loading,
    required this.showTitle,
  });

  final bool compact;
  final bool loading;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle) ...[
          Text(
            'CONTA',
            style: text.labelMedium?.copyWith(color: ForjaColors.textSecondary),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: loading
              ? null
              : () => context.read<AuthBloc>().add(
                  const AuthGoogleSignInRequested(),
                ),
          icon: loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.g_mobiledata_rounded, size: 28),
          label: Text(loading ? 'Conectando...' : 'Entrar com Google'),
        ),
      ],
    );
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
