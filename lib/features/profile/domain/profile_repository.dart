import 'child_profile.dart';

class ProfileAccessDenied implements Exception {
  const ProfileAccessDenied();

  static const message = 'Firestore denied profile access (permission-denied). '
      'Check the published rules for users/{parentUid} in the (default) database, '
      'then tap Retry.';

  @override
  String toString() => message;
}

class LoadedProfile {
  const LoadedProfile(this.profile, {this.isOffline = false});
  final ChildProfile? profile;
  final bool isOffline;
}

abstract interface class ProfileRepository {
  Future<LoadedProfile> load(String parentId);
  Future<void> save(String parentId, ChildProfile profile);
  Future<void> clearLocal(String parentId);
}
