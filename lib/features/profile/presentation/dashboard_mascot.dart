import 'dart:math' as math;

import 'package:flutter/material.dart';

class DashboardMascot extends StatefulWidget {
  const DashboardMascot({super.key});

  @override
  State<DashboardMascot> createState() => _DashboardMascotState();
}

class _DashboardMascotState extends State<DashboardMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_started) {
      _started = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Center(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            child: Image.asset(
              'assets/characters/wave.png',
              width: 128,
              height: 140,
              fit: BoxFit.contain,
              semanticLabel: 'Friendly sprout character waving hello',
            ),
            builder: (context, child) {
              final progress = _controller.value;
              final motion = math.sin(progress * math.pi * 4) *
                  math.sin(progress * math.pi);
              return Transform.translate(
                offset: Offset(0, -motion.abs() * 5),
                child: Transform.rotate(
                  key: const ValueKey('mascot-tilt'),
                  angle: motion * 0.045,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
