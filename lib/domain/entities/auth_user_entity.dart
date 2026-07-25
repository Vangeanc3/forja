import 'package:equatable/equatable.dart';

class AuthUserEntity extends Equatable {
  const AuthUserEntity({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.providerIds = const [],
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final List<String> providerIds;

  bool get isGuest => isAnonymous && providerIds.isEmpty;

  bool get hasGoogleProvider => providerIds.contains('google.com');
  bool get hasPasswordProvider => providerIds.contains('password');

  String get providerLabel {
    final List<String> labels = [];
    if (hasGoogleProvider) labels.add('Google');
    if (hasPasswordProvider) labels.add('E-mail');
    if (isAnonymous && labels.isEmpty) return 'Convidado';
    return labels.isEmpty ? 'Firebase' : labels.join(' + ');
  }

  String get displayLabel {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) return mail;

    return 'Conta Forja';
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    isAnonymous,
    providerIds,
  ];
}
