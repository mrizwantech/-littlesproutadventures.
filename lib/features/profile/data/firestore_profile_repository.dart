import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/child_profile.dart';
import '../domain/profile_repository.dart';
import 'local_profile_cache.dart';

class FirestoreProfileRepository implements ProfileRepository {
  final LocalProfileCache _local = LocalProfileCache();
  bool _configured = false;

  FirebaseFirestore get _store {
    final store = FirebaseFirestore.instance;
    if (!_configured) {
      // Only the explicit account-scoped cache should persist child data.
      store.settings = const Settings(persistenceEnabled: false);
      _configured = true;
    }
    return store;
  }

  void _checkParent(String parentId) {
    if (FirebaseAuth.instance.currentUser?.uid != parentId) {
      throw StateError('The parent session has changed.');
    }
  }

  Future<void> _cache(String parentId, ChildProfile profile) async {
    _checkParent(parentId);
    await _local.save(parentId, profile);
    if (FirebaseAuth.instance.currentUser?.uid != parentId) {
      await clearLocal(parentId);
      throw StateError('The parent session has changed.');
    }
  }

  Future<LoadedProfile> _offline(String parentId) async {
    final cached = await _local.load(parentId);
    _checkParent(parentId);
    if (cached == null) {
      throw StateError('Connect to the internet to load the child profile.');
    }
    return LoadedProfile(cached, isOffline: true);
  }

  @override
  Future<LoadedProfile> load(String parentId) async {
    _checkParent(parentId);
    DocumentSnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _store
          .collection('users')
          .doc(parentId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
    } on FirebaseException catch (error, stack) {
      if (error.code == 'permission-denied') {
        Error.throwWithStackTrace(const ProfileAccessDenied(), stack);
      }
      if (error.code != 'unavailable' && error.code != 'deadline-exceeded') {
        rethrow;
      }
      return _offline(parentId);
    } on TimeoutException {
      return _offline(parentId);
    }
    _checkParent(parentId);
    final data = snapshot.data();
    if (data == null) {
      await clearLocal(parentId);
      return const LoadedProfile(null);
    }
    final profile = LocalProfileCache.decode(data);
    await _cache(parentId, profile);
    return LoadedProfile(profile);
  }

  @override
  Future<void> save(String parentId, ChildProfile profile) async {
    _checkParent(parentId);
    try {
      await _store.collection('users').doc(parentId).set({
        ...LocalProfileCache.encode(profile),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
    } on FirebaseException catch (error, stack) {
      if (error.code == 'permission-denied') {
        Error.throwWithStackTrace(const ProfileAccessDenied(), stack);
      }
      rethrow;
    }
    _checkParent(parentId);
    await _cache(parentId, profile);
  }

  @override
  Future<void> clearLocal(String parentId) => _local.clear(parentId);
}
