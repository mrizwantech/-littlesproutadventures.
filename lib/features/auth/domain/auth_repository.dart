class SignInCancelled implements Exception {
  const SignInCancelled();
}

abstract interface class AuthRepository {
  Future<void> initialize();
  String? get currentParentId;
  Stream<String?> get parentChanges;
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
}
