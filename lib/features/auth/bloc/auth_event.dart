import 'package:equatable/equatable.dart';

import '../../../domain/entities/auth_user_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.user);

  final AuthUserEntity? user;

  @override
  List<Object?> get props => [user];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthAnonymousSignInRequested extends AuthEvent {
  const AuthAnonymousSignInRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
