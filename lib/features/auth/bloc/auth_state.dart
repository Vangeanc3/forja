import 'package:equatable/equatable.dart';

import '../../../domain/entities/auth_user_entity.dart';

const Object _unsetUser = Object();

enum AuthSubmissionStatus { idle, loading, success, failure }

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.submissionStatus = AuthSubmissionStatus.idle,
    this.errorMessage,
  });

  final AuthUserEntity? user;
  final AuthSubmissionStatus submissionStatus;
  final String? errorMessage;

  bool get isAuthenticated => user != null && !user!.isAnonymous;
  bool get isGuest => user?.isAnonymous ?? false;
  bool get isLoading => submissionStatus == AuthSubmissionStatus.loading;

  AuthState copyWith({
    Object? user = _unsetUser,
    AuthSubmissionStatus? submissionStatus,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) => AuthState(
    user: identical(user, _unsetUser) ? this.user : user as AuthUserEntity?,
    submissionStatus: submissionStatus ?? this.submissionStatus,
    errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [user, submissionStatus, errorMessage];
}
