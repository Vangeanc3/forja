import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/bootstrap/firebase_bootstrap.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../models/auth_user_model.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  static Future<void>? _googleInitialization;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  AuthUserEntity? get currentUser {
    if (!FirebaseBootstrap.initialized) return null;
    final user = _auth.currentUser;
    return user == null ? null : AuthUserModel.fromFirebaseUser(user);
  }

  Stream<AuthUserEntity?> authStateChanges() {
    if (!FirebaseBootstrap.initialized) {
      return Stream<AuthUserEntity?>.value(null);
    }

    return _auth.userChanges().asyncMap((user) async {
      if (user == null) return null;
      return _touchUser(user);
    });
  }

  Future<AuthUserEntity> signInAnonymously() async {
    _ensureFirebaseAvailable();

    try {
      final result = await _auth.signInAnonymously();
      return _touchUser(result.user);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  Future<AuthUserEntity> signInWithGoogle() async {
    _ensureFirebaseAvailable();

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});

        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          try {
            final result = await currentUser.linkWithPopup(provider);
            return _touchUser(result.user);
          } on FirebaseAuthException catch (error) {
            if (!_shouldFallbackToSignIn(error.code)) {
              throw AuthFailure.fromFirebase(error);
            }
          }
        }

        final result = await _auth.signInWithPopup(provider);
        return _touchUser(result.user);
      }

      await _ensureGoogleInitialized();

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AuthFailure(
          'Login com Google não está disponível neste dispositivo.',
        );
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthFailure(
          'Google não retornou o token de autenticação. Verifique a configuração OAuth/Firebase.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return _signInOrLink(credential);
    } on GoogleSignInException catch (error) {
      throw _googleFailure(error);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  Future<AuthUserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseAvailable();

    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _touchUser(result.user);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  Future<AuthUserEntity> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseAvailable();

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      return _signInOrLink(credential);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  Future<void> signOut() async {
    _ensureFirebaseAvailable();

    if (!kIsWeb) {
      try {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.signOut();
      } on Object catch (error, stackTrace) {
        debugPrint('Google sign out skipped: $error');
        if (kDebugMode) {
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }

    await _auth.signOut();
  }

  Future<AuthUserEntity> _signInOrLink(AuthCredential credential) async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      try {
        final result = await currentUser.linkWithCredential(credential);
        return _touchUser(result.user);
      } on FirebaseAuthException catch (error) {
        if (!_shouldFallbackToSignIn(error.code)) {
          throw AuthFailure.fromFirebase(error);
        }
        // Se já está vinculado ou algo similar, apenas prossegue para login normal
        // se não estiver logado, ou ignora se já estiver logado com esse mesmo cara.
      }
    }

    final result = await _auth.signInWithCredential(credential);
    return _touchUser(result.user);
  }

  Future<AuthUserEntity> linkEmailPassword({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseAvailable();
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const AuthFailure('Você precisa estar logado para vincular um e-mail.');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final result = await currentUser.linkWithCredential(credential);
      return _touchUser(result.user);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  Future<AuthUserEntity> _touchUser(User? user) async {
    if (user == null) {
      throw const AuthFailure('Firebase não retornou um usuário autenticado.');
    }

    final model = AuthUserModel.fromFirebaseUser(user);

    try {
      await _firestore.collection('users').doc(model.uid).set({
        'app': 'forja',
        'auth': model.toMap(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastSignedInAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      debugPrint('Firebase auth profile sync failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return model;
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitialization ??= GoogleSignIn.instance.initialize();
  }

  void _ensureFirebaseAvailable() {
    if (!FirebaseBootstrap.initialized) {
      throw const AuthFailure(
        'Firebase ainda não foi inicializado neste ambiente.',
      );
    }
  }

  bool _shouldFallbackToSignIn(String code) => {
    'account-exists-with-different-credential',
    'credential-already-in-use',
    'email-already-in-use',
    'provider-already-linked',
  }.contains(code);

  AuthFailure _googleFailure(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        return const AuthCancelled();
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return AuthFailure(
          'Google Sign-In está sem configuração OAuth válida. Detalhe: ${error.description ?? error.code.name}',
        );
      case GoogleSignInExceptionCode.uiUnavailable:
        return const AuthFailure(
          'A interface do Google Sign-In não está disponível agora.',
        );
      default:
        return AuthFailure(
          error.description ?? 'Não foi possível entrar com Google.',
        );
    }
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  factory AuthFailure.fromFirebase(FirebaseAuthException exception) {
    final message = switch (exception.code) {
      'account-exists-with-different-credential' =>
        'Já existe uma conta com este e-mail usando outro provedor.',
      'configuration-not-found' =>
        'Firebase Authentication ainda não foi iniciado ou configurado neste projeto.',
      'credential-already-in-use' || 'email-already-in-use' =>
        'Já existe uma conta vinculada a este e-mail.',
      'invalid-credential' ||
      'invalid-oauth-provider' ||
      'invalid-oauth-client-id' =>
        'A configuração OAuth do Firebase está inválida para este provedor.',
      'network-request-failed' =>
        'Sem conexão com a internet para autenticar agora.',
      'operation-not-allowed' =>
        'Este provedor de login ainda não foi habilitado no Firebase Console.',
      'user-disabled' => 'Esta conta foi desativada.',
      'user-not-found' => 'Nenhum usuário encontrado com este e-mail.',
      'wrong-password' => 'Senha incorreta para este usuário.',
      'invalid-email' => 'O formato do e-mail é inválido.',
      'weak-password' => 'A senha informada é muito fraca.',
      _ =>
        exception.message ??
            'Não foi possível autenticar no Firebase (${exception.code}).',
    };

    return AuthFailure(message);
  }

  @override
  String toString() => message;
}

class AuthCancelled extends AuthFailure {
  const AuthCancelled() : super('Login cancelado.');
}
