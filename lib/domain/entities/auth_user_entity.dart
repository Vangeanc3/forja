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

  bool get hasSocialProvider => providerIds.contains('google.com');

  String get providerLabel {
    if (providerIds.contains('google.com')) return 'Google';
    if (isAnonymous) return 'Convidado';
    return 'Firebase';
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
