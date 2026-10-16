import 'package:flutter/material.dart';

import '../domain/auth_repository.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.auth, this.onBack});
  final AuthRepository auth;
  final VoidCallback? onBack;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error, stack) {
      final cancelled = error is SignInCancelled;
      if (!cancelled) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stack,
          context: ErrorDescription('during parent sign-in'),
        ));
      }
      if (mounted) {
        setState(() => _error = cancelled
            ? 'Sign-in cancelled. You can try again.'
            : 'Sign-in failed. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF073C91),
        title: const Text('Little Sprout Adventures'),
        leading: widget.onBack == null
            ? null
            : BackButton(onPressed: _busy ? null : widget.onBack),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/little_learners_meadow.png',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(24, kToolbarHeight + 24, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    color: const Color(0xF5FFFFFF),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Parent sign-in',
                              textAlign: TextAlign.center,
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 12),
                          const Text(
                              textAlign: TextAlign.center,
                              'Use your own account to save your child\'s nickname and age band.'),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1F1F1F),
                              minimumSize: const Size(0, 56),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              side: const BorderSide(color: Color(0xFF747775)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Image.asset(
                              'assets/images/google_logo.png',
                              width: 20,
                              height: 20,
                              excludeFromSemantics: true,
                            ),
                            onPressed: _busy
                                ? null
                                : () => _signIn(widget.auth.signInWithGoogle),
                            label: const Text('Continue with Google',
                                textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            icon: const Icon(Icons.apple, size: 24),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 56),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            onPressed: _busy
                                ? null
                                : () => _signIn(widget.auth.signInWithApple),
                            label: const Text('Sign in with Apple',
                                textAlign: TextAlign.center),
                          ),
                          if (_busy)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          if (_error != null)
                            Text(_error!, semanticsLabel: _error),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
