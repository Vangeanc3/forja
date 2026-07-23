import 'package:firebase_auth/firebase_auth.dart';
import 'package:forja/domain/entities/auth_user_entity.dart';

class AuthUserModel extends AuthUserEntity {
  const AuthUserModel({
    required super.uid,
    super.email,
    super.displayName,
    super.photoUrl,
    super.isAnonymous,
    super.providerIds,
  });

  factory AuthUserModel.fromFirebaseUser(User user) {
    final providerIds = user.providerData
        .map((provider) => provider.providerId)
        .where((providerId) => providerId.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final normalizedProviderIds = providerIds.isEmpty && user.isAnonymous
        ? const ['anonymous']
        : List<String>.unmodifiable(providerIds);

    return AuthUserModel(
      uid: user.uid,
      email:
          user.email ?? _firstNonEmpty(user.providerData.map((p) => p.email)),
      displayName:
          user.displayName ??
          _firstNonEmpty(user.providerData.map((p) => p.displayName)),
      photoUrl:
          user.photoURL ??
          _firstNonEmpty(user.providerData.map((p) => p.photoURL)),
      isAnonymous: user.isAnonymous,
      providerIds: normalizedProviderIds,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'isAnonymous': isAnonymous,
    'providerIds': providerIds,
  };

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}
