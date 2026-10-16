import 'package:flutter/material.dart';

import 'app/little_learners_app.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/profile/data/firestore_profile_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final profiles = FirestoreProfileRepository();
  final auth = FirebaseAuthRepository();
  runApp(LittleLearnersApp(
    prepare: auth.initialize,
    home: AuthGate(auth: auth, profiles: profiles),
  ));
}
