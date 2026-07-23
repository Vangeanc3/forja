import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/bootstrap/firebase_bootstrap.dart';

class FirebaseSyncService {
  FirebaseSyncService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  bool _userDocumentTouched = false;
  Object? lastError;

  Future<bool> get isReady async => await _uid() != null;

  Future<void> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final uid = await _uid();
    if (uid == null) return;

    await _guard(() {
      return _firestore
          .collection('users')
          .doc(uid)
          .collection(collection)
          .doc(documentId)
          .set({
            ...data,
            'syncedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    });
  }

  Future<FirebaseSyncDocument?> getDocument(
    String collection,
    String documentId,
  ) async {
    final uid = await _uid();
    if (uid == null) return null;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection(collection)
          .doc(documentId)
          .get();
      lastError = null;
      return FirebaseSyncDocument.fromSnapshot(snapshot);
    } catch (error, stackTrace) {
      lastError = error;
      debugPrint('Firebase document read failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
      return null;
    }
  }

  Future<List<FirebaseSyncDocument>> getCollection(String collection) async {
    final uid = await _uid();
    if (uid == null) return const [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection(collection)
          .get();
      lastError = null;
      return snapshot.docs
          .map(FirebaseSyncDocument.fromSnapshot)
          .whereType<FirebaseSyncDocument>()
          .toList(growable: false);
    } catch (error, stackTrace) {
      lastError = error;
      debugPrint('Firebase collection read failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
      return const [];
    }
  }

  Future<void> deleteDocument(String collection, String documentId) async {
    final uid = await _uid();
    if (uid == null) return;

    await _guard(() {
      return _firestore
          .collection('users')
          .doc(uid)
          .collection(collection)
          .doc(documentId)
          .delete();
    });
  }

  Future<String?> _uid() async {
    if (!FirebaseBootstrap.initialized) return null;

    try {
      final currentUser = _auth.currentUser;
      final user = currentUser ?? (await _auth.signInAnonymously()).user;
      final uid = user?.uid;
      if (uid == null) return null;

      if (!_userDocumentTouched) {
        _userDocumentTouched = true;
        await _firestore.collection('users').doc(uid).set({
          'app': 'forja',
          'lastActiveAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      lastError = null;
      return uid;
    } catch (error, stackTrace) {
      lastError = error;
      debugPrint('Firebase auth/sync is not available: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
      return null;
    }
  }

  Future<void> _guard(Future<void> Function() operation) async {
    try {
      await operation();
      lastError = null;
    } catch (error, stackTrace) {
      lastError = error;
      debugPrint('Firebase sync failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }
}

class FirebaseSyncDocument {
  const FirebaseSyncDocument({
    required this.id,
    required this.data,
    this.syncedAt,
  });

  final String id;
  final Map<String, dynamic> data;
  final DateTime? syncedAt;

  static FirebaseSyncDocument? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final raw = snapshot.data();
    if (!snapshot.exists || raw == null) return null;

    return FirebaseSyncDocument(
      id: snapshot.id,
      data: _normalizeMap(raw),
      syncedAt: _dateFrom(raw['syncedAt']) ?? _dateFrom(raw['updatedAt']),
    );
  }

  static Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> map) {
    return map.map(
      (key, value) => MapEntry(key.toString(), _normalizeValue(value)),
    );
  }

  static Object? _normalizeValue(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) return _normalizeMap(value);
    if (value is List) return value.map(_normalizeValue).toList();
    return value;
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
