import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../domain/entities/auth_user_entity.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(AuthState(user: _repository.currentUser)) {
    on<AuthStarted>(_onStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthEmailPasswordSignInRequested>(_onEmailPasswordSignInRequested);
    on<AuthEmailPasswordSignUpRequested>(_onEmailPasswordSignUpRequested);
    on<AuthLinkEmailPasswordRequested>(_onLinkEmailPasswordRequested);
    on<AuthAnonymousSignInRequested>(_onAnonymousSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);

    _subscription = _repository.authStateChanges().listen(
      (user) => add(AuthUserChanged(user)),
    );
    add(const AuthStarted());
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthUserEntity?> _subscription;

  void _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        user: _repository.currentUser,
        submissionStatus: AuthSubmissionStatus.idle,
        clearErrorMessage: true,
      ),
    );
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        user: event.user,
        submissionStatus: AuthSubmissionStatus.idle,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) => _authenticate(emit, _repository.signInWithGoogle);

  Future<void> _onEmailPasswordSignInRequested(
    AuthEmailPasswordSignInRequested event,
    Emitter<AuthState> emit,
  ) => _authenticate(
    emit,
    () => _repository.signInWithEmailAndPassword(
      email: event.email,
      password: event.password,
    ),
  );

  Future<void> _onEmailPasswordSignUpRequested(
    AuthEmailPasswordSignUpRequested event,
    Emitter<AuthState> emit,
  ) => _authenticate(
    emit,
    () => _repository.createUserWithEmailAndPassword(
      email: event.email,
      password: event.password,
    ),
  );

  Future<void> _onLinkEmailPasswordRequested(
    AuthLinkEmailPasswordRequested event,
    Emitter<AuthState> emit,
  ) => _authenticate(
    emit,
    () => _repository.linkEmailPassword(
      email: event.email,
      password: event.password,
    ),
  );

  Future<void> _onAnonymousSignInRequested(
    AuthAnonymousSignInRequested event,
    Emitter<AuthState> emit,
  ) => _authenticate(emit, _repository.signInAnonymously);

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: AuthSubmissionStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.signOut();
      emit(
        state.copyWith(
          user: null,
          submissionStatus: AuthSubmissionStatus.success,
          clearErrorMessage: true,
        ),
      );
    } on AuthFailure catch (error) {
      emit(
        state.copyWith(
          submissionStatus: AuthSubmissionStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          submissionStatus: AuthSubmissionStatus.failure,
          errorMessage: 'Não foi possível sair da conta.',
        ),
      );
    }
  }

  Future<void> _authenticate(
    Emitter<AuthState> emit,
    Future<AuthUserEntity> Function() action,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: AuthSubmissionStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final user = await action();
      emit(
        state.copyWith(
          user: user,
          submissionStatus: AuthSubmissionStatus.success,
          clearErrorMessage: true,
        ),
      );
    } on AuthCancelled {
      emit(
        state.copyWith(
          submissionStatus: AuthSubmissionStatus.idle,
          clearErrorMessage: true,
        ),
      );
    } on AuthFailure catch (error) {
      emit(
        state.copyWith(
          submissionStatus: AuthSubmissionStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          submissionStatus: AuthSubmissionStatus.failure,
          errorMessage: 'Não foi possível autenticar agora.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
