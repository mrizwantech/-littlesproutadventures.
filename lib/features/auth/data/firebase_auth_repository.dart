import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  bool _googleInitialized = false;

  @override
  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }
    await FirebaseAuth.instance.authStateChanges().first;
  }

  @override
  String? get currentParentId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Stream<String?> get parentChanges =>
      FirebaseAuth.instance.authStateChanges().map((user) => user?.uid);

  @override
  Future<void> signInWithGoogle() async {
    GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const SignInCancelled();
      }
      rethrow;
    }
    final token = account.authentication.idToken;
    if (token == null) throw StateError('Google did not supply an ID token.');
    await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  }

  @override
  Future<void> signInWithApple() async {
    try {
      await FirebaseAuth.instance.signInWithProvider(
        AppleAuthProvider()..addScope('email'),
      );
    } on FirebaseAuthException catch (error) {
      if (const ['web-context-canceled', 'canceled', 'user-cancelled']
          .contains(error.code)) {
        throw const SignInCancelled();
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
