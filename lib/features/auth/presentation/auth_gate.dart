import 'package:flutter/material.dart';

import '../domain/auth_repository.dart';
import 'sign_in_screen.dart';
import '../../profile/domain/profile_repository.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../welcome/presentation/welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth, required this.profiles});
  final AuthRepository auth;
  final ProfileRepository profiles;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<String?> _changes = widget.auth.parentChanges;
  bool _entered = false;

  void _getStarted() => setState(() => _entered = true);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _changes,
      initialData: widget.auth.currentParentId,
      builder: (context, snapshot) {
        if (!_entered) {
          return WelcomeScreen(onGetStarted: _getStarted);
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
                child: Text(
                    'Unable to read your sign-in session. Restart the app.')),
          );
        }
        final parentId = snapshot.data;
        if (parentId == null) {
          return SignInScreen(
            auth: widget.auth,
            onBack: () => setState(() => _entered = false),
          );
        }
        return ProfileScreen(
          key: ValueKey(parentId),
          parentId: parentId,
          repository: widget.profiles,
          signOut: () async {
            await widget.profiles.clearLocal(parentId);
            await widget.auth.signOut();
            if (mounted) setState(() => _entered = false);
          },
        );
      },
    );
  }
}
