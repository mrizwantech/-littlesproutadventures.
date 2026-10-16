import 'package:flutter/material.dart';

import '../../../core/widgets/app_title.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.onRetry});

  static const assetPath = 'assets/images/little_learners_meadow.png';

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB9EEFA),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            excludeFromSemantics: true,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTitle(),
                      SizedBox(height: 8),
                      Text(
                        'Play • Learn • Grow',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF073C91),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onRetry == null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(48, 24, 48, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          minHeight: 12,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          color: Color(0xFF1684E6),
                          backgroundColor: Color(0xCCFFFFFF),
                          semanticsLabel: 'Preparing Little Sprout Adventures',
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: Color(0xFF005CA8),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (onRetry != null)
            SafeArea(
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to prepare the app. Please retry.'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: onRetry,
                          child: const Text('Retry'),
                        ),
                      ],
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
