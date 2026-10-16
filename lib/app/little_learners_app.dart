import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/welcome/presentation/welcome_screen.dart';

class LittleLearnersApp extends StatefulWidget {
  const LittleLearnersApp({super.key, this.prepare, this.home});

  final Future<void> Function()? prepare;
  final Widget? home;

  @override
  State<LittleLearnersApp> createState() => _LittleLearnersAppState();
}

class _LittleLearnersAppState extends State<LittleLearnersApp> {
  bool _started = false;
  bool _ready = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _prepare();
    }
  }

  Future<void> _prepare() async {
    try {
      Object? imageError;
      StackTrace? imageStack;
      await precacheImage(
        const AssetImage(SplashScreen.assetPath),
        context,
        onError: (error, stack) {
          imageError = error;
          imageStack = stack;
        },
      );
      if (imageError != null) {
        Error.throwWithStackTrace(
            imageError!, imageStack ?? StackTrace.current);
      }
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final prepare = widget.prepare;
      await Future.wait<void>([
        Future<void>.delayed(const Duration(seconds: 2)),
        if (prepare != null) prepare(),
      ]);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Little Sprout Adventures startup',
        context: ErrorDescription('while preparing the app'),
      ));
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    _prepare();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Little Sprout Adventures',
      theme: AppTheme.light,
      home: _ready
          ? widget.home ?? const WelcomeScreen()
          : SplashScreen(onRetry: _failed ? _retry : null),
    );
  }
}
